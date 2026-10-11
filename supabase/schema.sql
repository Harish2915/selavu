-- ==============================================================================
-- SELAVU - Trip Expense & Group Settlement Manager
-- Supabase Database Schema, Indexes, RLS Policies, and Triggers
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. PROFILES TABLE (Linked with Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. TRIPS TABLE
CREATE TABLE IF NOT EXISTS public.trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    from_date DATE NOT NULL,
    to_date DATE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed')),
    currency TEXT NOT NULL DEFAULT 'INR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. TRIP MEMBERS TABLE
CREATE TABLE IF NOT EXISTS public.trip_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    phone TEXT,
    is_owner BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    color TEXT,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 6. EXPENSES TABLE (Stored in paise: integer smallest monetary unit)
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    payer_id UUID NOT NULL REFERENCES public.trip_members(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
    expense_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    split_type TEXT NOT NULL DEFAULT 'equal' CHECK (split_type IN ('equal', 'custom')),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 7. EXPENSE SHARES TABLE (Individual share per member in paise)
CREATE TABLE IF NOT EXISTS public.expense_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.trip_members(id) ON DELETE CASCADE,
    share_paise BIGINT NOT NULL CHECK (share_paise >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 8. PAYMENTS TABLE (Direct money transfers/advances between members, e.g. Arun gave You ₹500)
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    from_member_id UUID NOT NULL REFERENCES public.trip_members(id) ON DELETE CASCADE,
    to_member_id UUID NOT NULL REFERENCES public.trip_members(id) ON DELETE CASCADE,
    amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
    payment_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- INDEXES FOR MAXIMUM QUERY PERFORMANCE
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_trips_owner ON public.trips(owner_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON public.trips(status);
CREATE INDEX IF NOT EXISTS idx_trip_members_trip ON public.trip_members(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_members_user ON public.trip_members(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_trip ON public.expenses(trip_id);
CREATE INDEX IF NOT EXISTS idx_expenses_payer ON public.expenses(payer_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expense_shares_expense ON public.expense_shares(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_shares_member ON public.expense_shares(member_id);
CREATE INDEX IF NOT EXISTS idx_payments_trip ON public.payments(trip_id);
CREATE INDEX IF NOT EXISTS idx_payments_from ON public.payments(from_member_id);
CREATE INDEX IF NOT EXISTS idx_payments_to ON public.payments(to_member_id);

-- ==============================================================================
-- AUTOMATIC PROFILE TRIGGER ON SIGNUP
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name, phone, avatar_url)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
        new.raw_user_meta_data->>'phone',
        new.raw_user_meta_data->>'avatar_url'
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Helper security function: Checks if authenticated user has access to a trip
CREATE OR REPLACE FUNCTION public.has_trip_access(check_trip_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.trips
        WHERE id = check_trip_id
        AND (
            owner_id = auth.uid()
            OR id IN (
                SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid()
            )
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles Policies
CREATE POLICY "Users can read own profile or fellow trip members"
    ON public.profiles FOR SELECT
    USING (
        id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.trip_members tm1
            JOIN public.trip_members tm2 ON tm1.trip_id = tm2.trip_id
            WHERE tm1.user_id = auth.uid() AND tm2.user_id = profiles.id
        )
    );

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid());

CREATE POLICY "Users can insert their profile"
    ON public.profiles FOR INSERT
    WITH CHECK (id = auth.uid());

-- Trips Policies
CREATE POLICY "Users can select trips they own or belong to"
    ON public.trips FOR SELECT
    USING (
        owner_id = auth.uid()
        OR id IN (SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can create their own trips"
    ON public.trips FOR INSERT
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Trip owners can update their trips"
    ON public.trips FOR UPDATE
    USING (owner_id = auth.uid());

CREATE POLICY "Trip owners can delete their trips"
    ON public.trips FOR DELETE
    USING (owner_id = auth.uid());

-- Trip Members Policies
CREATE POLICY "Users can view members of trips they have access to"
    ON public.trip_members FOR SELECT
    USING (public.has_trip_access(trip_id));

CREATE POLICY "Trip owners can add members"
    ON public.trip_members FOR INSERT
    WITH CHECK (
        EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND owner_id = auth.uid())
    );

CREATE POLICY "Trip owners can update members"
    ON public.trip_members FOR UPDATE
    USING (
        EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND owner_id = auth.uid())
    );

CREATE POLICY "Trip owners can remove members"
    ON public.trip_members FOR DELETE
    USING (
        EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND owner_id = auth.uid())
    );

-- Expenses Policies
CREATE POLICY "Users can view expenses for authorized trips"
    ON public.expenses FOR SELECT
    USING (public.has_trip_access(trip_id));

CREATE POLICY "Authorized users can add expenses"
    ON public.expenses FOR INSERT
    WITH CHECK (public.has_trip_access(trip_id));

CREATE POLICY "Authorized users can update expenses"
    ON public.expenses FOR UPDATE
    USING (public.has_trip_access(trip_id));

CREATE POLICY "Authorized users can delete expenses"
    ON public.expenses FOR DELETE
    USING (public.has_trip_access(trip_id));

-- Expense Shares Policies
CREATE POLICY "Users can view shares for accessible expenses"
    ON public.expense_shares FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.expenses e
            WHERE e.id = expense_shares.expense_id
            AND public.has_trip_access(e.trip_id)
        )
    );

CREATE POLICY "Users can manage expense shares"
    ON public.expense_shares FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.expenses e
            WHERE e.id = expense_shares.expense_id
            AND public.has_trip_access(e.trip_id)
        )
    );

-- Payments Policies
CREATE POLICY "Users can view payments for authorized trips"
    ON public.payments FOR SELECT
    USING (public.has_trip_access(trip_id));

CREATE POLICY "Authorized users can insert payments"
    ON public.payments FOR INSERT
    WITH CHECK (public.has_trip_access(trip_id));

CREATE POLICY "Authorized users can update payments"
    ON public.payments FOR UPDATE
    USING (public.has_trip_access(trip_id));

CREATE POLICY "Authorized users can delete payments"
    ON public.payments FOR DELETE
    USING (public.has_trip_access(trip_id));

-- Categories Policies
CREATE POLICY "Anyone authenticated can view default categories or their own"
    ON public.categories FOR SELECT
    USING (is_default = true OR created_by = auth.uid());

CREATE POLICY "Users can insert custom categories"
    ON public.categories FOR INSERT
    WITH CHECK (created_by = auth.uid());

-- ==============================================================================
-- DEFAULT CATEGORIES SEED DATA
-- ==============================================================================
INSERT INTO public.categories (name, icon, color, is_default)
VALUES
    ('Hotel', 'hotel', '#FF7A00', true),
    ('Food', 'food', '#FA4A0C', true),
    ('Bus', 'bus', '#FF9F43', true),
    ('Train', 'train', '#54A0FF', true),
    ('Auto', 'auto', '#10AC84', true),
    ('Cab', 'cab', '#EE5253', true),
    ('Fuel', 'fuel', '#FF6B6B', true),
    ('Tickets', 'tickets', '#48DBFB', true),
    ('Temple', 'temple', '#FFA502', true),
    ('Shopping', 'shopping', '#9B59B6', true),
    ('Snacks', 'snacks', '#E67E22', true),
    ('Other', 'other', '#7F8C8D', true)
ON CONFLICT DO NOTHING;
