-- ============================================================
-- Smart Road Monitoring System — Supabase Database Schema
-- NEW FILE — Run this in Supabase SQL Editor
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- ENUM TYPES
-- ============================================================

CREATE TYPE user_role AS ENUM ('citizen', 'worker', 'admin');
CREATE TYPE report_status AS ENUM ('pending', 'assigned', 'in_progress', 'completed');
CREATE TYPE worker_status AS ENUM ('available', 'busy', 'offline');
CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');

-- ============================================================
-- USERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,                          -- Firebase UID
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role user_role NOT NULL DEFAULT 'citizen',
    phone TEXT,
    avatar_url TEXT,
    fcm_token TEXT,                               -- For push notifications
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ============================================================
-- REPORTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN (
        'pothole', 'road_obstruction', 'water_logging',
        'broken_streetlight', 'garbage'
    )),
    description TEXT,
    image_url TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    status report_status NOT NULL DEFAULT 'pending',
    assigned_worker_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    ai_detection_result JSONB,                     -- AI model output
    completion_image_url TEXT,
    completion_remarks TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_user_id ON reports(user_id);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_category ON reports(category);
CREATE INDEX idx_reports_assigned_worker ON reports(assigned_worker_id);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);
CREATE INDEX idx_reports_location ON reports(latitude, longitude);

-- ============================================================
-- WORKERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS workers (
    worker_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    status worker_status NOT NULL DEFAULT 'available',
    total_tasks_completed INTEGER DEFAULT 0,
    current_task_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workers_status ON workers(status);

-- ============================================================
-- ATTENDANCE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    login_time TIMESTAMPTZ,
    logout_time TIMESTAMPTZ,
    login_photo TEXT,                              -- Base64 or URL
    logout_photo TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_attendance_worker_id ON attendance(worker_id);
CREATE INDEX idx_attendance_date ON attendance(date DESC);
CREATE UNIQUE INDEX idx_attendance_worker_date ON attendance(worker_id, date);

-- ============================================================
-- SUPPORT TICKETS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    response TEXT,
    status ticket_status NOT NULL DEFAULT 'open',
    responded_by TEXT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);

-- ============================================================
-- NOTIFICATIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,                           -- 'assignment', 'status_update', 'completion'
    report_id UUID REFERENCES reports(id) ON DELETE CASCADE,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- ============================================================
-- AUTO-UPDATE TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at
    BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workers_updated_at
    BEFORE UPDATE ON workers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_tickets_updated_at
    BEFORE UPDATE ON support_tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users: can read own record, admins can read all
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id);

CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

-- Reports: citizens see own, workers see assigned, admins see all
CREATE POLICY "Citizens can view own reports" ON reports
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Workers can view assigned reports" ON reports
    FOR SELECT USING (auth.uid()::text = assigned_worker_id);

CREATE POLICY "Admins can view all reports" ON reports
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::text AND role = 'admin')
    );

CREATE POLICY "Citizens can create reports" ON reports
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Notifications: users see own only
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid()::text = user_id);

-- ============================================================
-- SEED DATA (Optional — remove for production)
-- ============================================================

-- Insert a sample admin user (replace with real Firebase UID)
-- INSERT INTO users (id, name, email, role)
-- VALUES ('FIREBASE_ADMIN_UID', 'Admin User', 'admin@smartroad.com', 'admin');
