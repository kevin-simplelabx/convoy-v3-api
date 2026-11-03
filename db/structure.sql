SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.academic_terms (
    id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    "position" integer NOT NULL,
    starts_on date,
    ends_on date,
    cca_starts_on date,
    cca_ends_on date
);


--
-- Name: academic_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.academic_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: academic_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.academic_terms_id_seq OWNED BY public.academic_terms.id;


--
-- Name: academic_years; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.academic_years (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    key character varying NOT NULL,
    start_year integer NOT NULL,
    start_month integer NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    structure character varying DEFAULT 'semester'::character varying NOT NULL,
    period_count integer DEFAULT 2 NOT NULL,
    operating_days integer[] DEFAULT '{1,2,3,4,5}'::integer[] NOT NULL,
    cca_same_as_terms boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: academic_years_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.academic_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: academic_years_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.academic_years_id_seq OWNED BY public.academic_years.id;


--
-- Name: allowlisted_jwts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.allowlisted_jwts (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    company_id bigint,
    jti character varying NOT NULL,
    aud character varying,
    exp timestamp(6) without time zone NOT NULL,
    name character varying,
    last_used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: allowlisted_jwts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.allowlisted_jwts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allowlisted_jwts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.allowlisted_jwts_id_seq OWNED BY public.allowlisted_jwts.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: attendants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendants (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    phone character varying,
    photo character varying,
    notes text,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: attendants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendants_id_seq OWNED BY public.attendants.id;


--
-- Name: audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audits (
    id bigint NOT NULL,
    auditable_id integer,
    auditable_type character varying,
    associated_id integer,
    associated_type character varying,
    user_id integer,
    user_type character varying,
    username character varying,
    action character varying,
    audited_changes jsonb,
    version integer DEFAULT 0,
    comment character varying,
    remote_address character varying,
    request_uuid character varying,
    created_at timestamp(6) without time zone
);


--
-- Name: audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audits_id_seq OWNED BY public.audits.id;


--
-- Name: bank_branches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bank_branches (
    id bigint NOT NULL,
    bank_id bigint NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    account_prefix character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bank_branches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bank_branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_branches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bank_branches_id_seq OWNED BY public.bank_branches.id;


--
-- Name: banks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.banks (
    id bigint NOT NULL,
    key character varying NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    short_name character varying NOT NULL,
    branch_rule character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT banks_branch_rule CHECK (((branch_rule)::text = ANY (ARRAY[('pre3'::character varying)::text, ('pre3drop'::character varying)::text, ('posb'::character varying)::text, ('sc'::character varying)::text, ('uob'::character varying)::text, ('list'::character varying)::text])))
);


--
-- Name: banks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: banks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.banks_id_seq OWNED BY public.banks.id;


--
-- Name: booking_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_attachments (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    file character varying NOT NULL,
    uploaded_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: booking_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_attachments_id_seq OWNED BY public.booking_attachments.id;


--
-- Name: booking_cancel_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_cancel_requests (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    booking_trip_id bigint,
    reason text,
    requested_by_name character varying NOT NULL,
    requested_at timestamp(6) without time zone NOT NULL,
    status character varying DEFAULT 'open'::character varying NOT NULL,
    resolved_at timestamp(6) without time zone,
    resolved_by_id bigint,
    resolution_note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: booking_cancel_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_cancel_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_cancel_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_cancel_requests_id_seq OWNED BY public.booking_cancel_requests.id;


--
-- Name: booking_days; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_days (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    date date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: booking_days_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_days_id_seq OWNED BY public.booking_days.id;


--
-- Name: booking_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_events (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    booking_trip_id bigint,
    kind character varying NOT NULL,
    actor_name character varying,
    message character varying NOT NULL,
    occurred_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: booking_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_events_id_seq OWNED BY public.booking_events.id;


--
-- Name: booking_trip_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_trip_changes (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_trip_id bigint NOT NULL,
    changed_by_id bigint,
    items character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: booking_trip_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_trip_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_trip_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_trip_changes_id_seq OWNED BY public.booking_trip_changes.id;


--
-- Name: booking_trip_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_trip_points (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_trip_id bigint NOT NULL,
    leg character varying DEFAULT 'out'::character varying NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    address character varying,
    lat numeric(10,7),
    lng numeric(10,7),
    use character varying DEFAULT 'both'::character varying NOT NULL,
    note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: booking_trip_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_trip_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_trip_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_trip_points_id_seq OWNED BY public.booking_trip_points.id;


--
-- Name: booking_trip_standbys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_trip_standbys (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_trip_id bigint NOT NULL,
    leg character varying DEFAULT 'out'::character varying NOT NULL,
    location character varying NOT NULL,
    minutes integer DEFAULT 10 NOT NULL,
    lat numeric(10,7),
    lng numeric(10,7),
    note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: booking_trip_standbys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_trip_standbys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_trip_standbys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_trip_standbys_id_seq OWNED BY public.booking_trip_standbys.id;


--
-- Name: booking_trip_vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_trip_vehicles (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_trip_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    count integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: booking_trip_vehicles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_trip_vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_trip_vehicles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_trip_vehicles_id_seq OWNED BY public.booking_trip_vehicles.id;


--
-- Name: booking_trips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_trips (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    booking_day_id bigint NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    kind character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    label character varying,
    start_time integer NOT NULL,
    return_time integer,
    hours numeric(5,2),
    airport_direction character varying,
    flight_number character varying,
    terminal character varying,
    wait_minutes integer,
    meet_and_greet boolean DEFAULT false NOT NULL,
    signboard_name character varying,
    pax integer DEFAULT 0 NOT NULL,
    luggage_on boolean DEFAULT false NOT NULL,
    luggage_cabin integer DEFAULT 0 NOT NULL,
    luggage_medium integer DEFAULT 0 NOT NULL,
    luggage_large integer DEFAULT 0 NOT NULL,
    luggage_extra_large integer DEFAULT 0 NOT NULL,
    luggage_oversized integer DEFAULT 0 NOT NULL,
    contact_name character varying,
    contact_phone character varying,
    note text,
    distance_km numeric(8,1),
    return_distance_km numeric(8,1),
    estimate_amount numeric(12,2) DEFAULT 0.0 NOT NULL,
    estimate_lines jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    approved_at timestamp(6) without time zone,
    approved_by_id bigint,
    approval_how character varying,
    approval_note text,
    acknowledged_at timestamp(6) without time zone,
    acknowledged_by_name character varying,
    acknowledged_how character varying,
    rejected_at timestamp(6) without time zone,
    rejected_by_id bigint,
    rejected_by_name character varying,
    rejected_by_client boolean DEFAULT false NOT NULL,
    rejection_reason text,
    cancelled_at timestamp(6) without time zone
);


--
-- Name: booking_trips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_trips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_trips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_trips_id_seq OWNED BY public.booking_trips.id;


--
-- Name: bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    number character varying NOT NULL,
    client_id bigint NOT NULL,
    client_site_id bigint,
    client_end_customer_id bigint,
    service_for character varying,
    coordinator_name character varying NOT NULL,
    coordinator_org character varying,
    coordinator_email character varying,
    coordinator_phone character varying,
    po_number character varying,
    cost_centre character varying,
    notes text,
    source character varying DEFAULT 'console'::character varying NOT NULL,
    created_by_id bigint,
    estimate_amount numeric(12,2) DEFAULT 0.0 NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookings_id_seq OWNED BY public.bookings.id;


--
-- Name: bus_request_answer_moves; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bus_request_answer_moves (
    id bigint NOT NULL,
    bus_request_id bigint NOT NULL,
    from_date date,
    to_date date NOT NULL,
    reason character varying NOT NULL,
    moved_at timestamp with time zone NOT NULL,
    moved_by_id bigint
);


--
-- Name: bus_request_answer_moves_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bus_request_answer_moves_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bus_request_answer_moves_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bus_request_answer_moves_id_seq OWNED BY public.bus_request_answer_moves.id;


--
-- Name: bus_request_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bus_request_events (
    id bigint NOT NULL,
    bus_request_id bigint NOT NULL,
    at timestamp with time zone NOT NULL,
    by_name character varying NOT NULL,
    user_id bigint,
    text text NOT NULL
);


--
-- Name: bus_request_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bus_request_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bus_request_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bus_request_events_id_seq OWNED BY public.bus_request_events.id;


--
-- Name: bus_request_places; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bus_request_places (
    id bigint NOT NULL,
    bus_request_id bigint NOT NULL,
    session character varying NOT NULL,
    school_route_id bigint,
    route_label character varying,
    kind character varying NOT NULL,
    stop_name character varying,
    delta_minutes numeric(5,1)
);


--
-- Name: bus_request_places_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bus_request_places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bus_request_places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bus_request_places_id_seq OWNED BY public.bus_request_places.id;


--
-- Name: bus_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bus_requests (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    academic_year_id bigint,
    family_id bigint,
    school_rider_id bigint,
    code character varying NOT NULL,
    kind character varying DEFAULT 'new'::character varying NOT NULL,
    source character varying DEFAULT 'app'::character varying NOT NULL,
    status character varying DEFAULT 'Requested'::character varying NOT NULL,
    renew boolean DEFAULT false NOT NULL,
    same boolean DEFAULT false NOT NULL,
    mid boolean DEFAULT false NOT NULL,
    tags character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    child_name character varying NOT NULL,
    level character varying,
    class_name character varying,
    student_no character varying,
    birth_date date,
    medical text,
    cca_days integer[] DEFAULT '{}'::integer[] NOT NULL,
    parent_name character varying,
    parent_phone character varying,
    parent_email character varying,
    am boolean DEFAULT true NOT NULL,
    pm boolean DEFAULT true NOT NULL,
    cca boolean DEFAULT false NOT NULL,
    address character varying,
    postal character varying,
    lat numeric(10,7),
    lng numeric(10,7),
    km numeric(6,2),
    estimate numeric(12,2),
    start_when character varying,
    start_on date,
    fix_why character varying,
    fix_note character varying,
    fee_paid boolean DEFAULT true NOT NULL,
    policy_version integer,
    submitted_at timestamp with time zone NOT NULL,
    acked_at timestamp with time zone,
    acked_by_id bigint,
    answer_by date,
    ack_note text,
    ack_plan_weeks integer,
    reason character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    quote_amount numeric(12,2),
    quote_base numeric(12,2),
    quote_unit character varying,
    quote_note text,
    quoted_at timestamp with time zone,
    quoted_by_id bigint,
    offer_by timestamp with time zone,
    effective_on date,
    current_fare numeric(12,2),
    old_address character varying,
    old_postal character varying,
    new_stop character varying,
    agree character varying,
    old_am boolean,
    old_pm boolean,
    old_cca boolean,
    adds boolean DEFAULT false NOT NULL,
    last_on date,
    stop_why character varying,
    stop_why_note character varying,
    notice_n integer,
    notice_unit character varying,
    earliest_on date,
    early boolean DEFAULT false NOT NULL,
    confirmed_at timestamp with time zone,
    confirmed_by_id bigint,
    confirm_note text,
    pay_to date,
    planned_at timestamp with time zone,
    planned_ok boolean,
    plan_lines character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    ended_on date,
    ended_at timestamp with time zone,
    ended_by_id bigint,
    rider_patched_on date,
    level_moved_on date
);


--
-- Name: bus_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bus_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bus_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bus_requests_id_seq OWNED BY public.bus_requests.id;


--
-- Name: bus_session_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bus_session_variants (
    id bigint NOT NULL,
    bus_session_id bigint NOT NULL,
    "position" integer NOT NULL,
    days integer[] DEFAULT '{}'::integer[] NOT NULL,
    arrive_from integer,
    arrive_to integer,
    dismissal integer,
    depart integer
);


--
-- Name: bus_session_variants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bus_session_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bus_session_variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bus_session_variants_id_seq OWNED BY public.bus_session_variants.id;


--
-- Name: bus_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bus_sessions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    direction character varying NOT NULL,
    cca boolean DEFAULT false NOT NULL,
    service character varying DEFAULT 'd2d'::character varying NOT NULL,
    max_journey_minutes integer DEFAULT 60 NOT NULL,
    days integer[] DEFAULT '{}'::integer[] NOT NULL,
    arrive_from integer,
    arrive_to integer,
    dismissal integer,
    depart integer,
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bus_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bus_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bus_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bus_sessions_id_seq OWNED BY public.bus_sessions.id;


--
-- Name: calendar_days; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_days (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    calendar_id bigint NOT NULL,
    kind character varying NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    label character varying,
    usual_time integer,
    new_time integer,
    shift_minutes integer,
    in_place_of date,
    notify_drivers boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT calendar_days_range CHECK ((ends_on >= starts_on))
);


--
-- Name: calendar_days_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calendar_days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calendar_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calendar_days_id_seq OWNED BY public.calendar_days.id;


--
-- Name: calendars; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendars (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    kind character varying NOT NULL,
    observed_holidays character varying DEFAULT 'off'::character varying NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    morning_time integer DEFAULT 450 NOT NULL,
    afternoon_time integer DEFAULT 810 NOT NULL
);


--
-- Name: calendars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calendars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calendars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calendars_id_seq OWNED BY public.calendars.id;


--
-- Name: cca_bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cca_bookings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    family_id bigint NOT NULL,
    school_rider_id bigint,
    school_bill_id bigint,
    child_name character varying NOT NULL,
    class_name character varying,
    date date NOT NULL,
    price numeric(12,2) NOT NULL,
    paid_on date NOT NULL,
    method character varying NOT NULL,
    late boolean DEFAULT false NOT NULL,
    not_riding boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cca_bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cca_bookings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cca_bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cca_bookings_id_seq OWNED BY public.cca_bookings.id;


--
-- Name: cca_credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cca_credits (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    family_id bigint NOT NULL,
    cca_booking_id bigint,
    child_name character varying,
    amount numeric(12,2) NOT NULL,
    date date NOT NULL,
    reason character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cca_credits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cca_credits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cca_credits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cca_credits_id_seq OWNED BY public.cca_credits.id;


--
-- Name: cca_off_days; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cca_off_days (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    date date NOT NULL,
    reason character varying NOT NULL,
    by_name character varying,
    user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cca_off_days_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cca_off_days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cca_off_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cca_off_days_id_seq OWNED BY public.cca_off_days.id;


--
-- Name: cca_ride_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cca_ride_settings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    price numeric(12,2) DEFAULT 0.0 NOT NULL,
    days integer[] DEFAULT '{2,4}'::integer[] NOT NULL,
    seats integer DEFAULT 40 NOT NULL,
    saved_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cca_ride_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cca_ride_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cca_ride_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cca_ride_settings_id_seq OWNED BY public.cca_ride_settings.id;


--
-- Name: client_billing_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_billing_contacts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    billable_type character varying NOT NULL,
    billable_id bigint NOT NULL,
    name character varying,
    email character varying,
    send_as character varying DEFAULT 'to'::character varying NOT NULL,
    attention boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT client_billing_contacts_send_as CHECK (((send_as)::text = ANY (ARRAY[('to'::character varying)::text, ('cc'::character varying)::text])))
);


--
-- Name: client_billing_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_billing_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_billing_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_billing_contacts_id_seq OWNED BY public.client_billing_contacts.id;


--
-- Name: client_bookable_vehicle_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_bookable_vehicle_types (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    client_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: client_bookable_vehicle_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_bookable_vehicle_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_bookable_vehicle_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_bookable_vehicle_types_id_seq OWNED BY public.client_bookable_vehicle_types.id;


--
-- Name: client_end_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_end_customers (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    client_id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: client_end_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_end_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_end_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_end_customers_id_seq OWNED BY public.client_end_customers.id;


--
-- Name: client_invoice_line_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_invoice_line_runs (
    id bigint NOT NULL,
    client_invoice_line_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    start_time integer,
    trip_label character varying,
    amount numeric(12,2) NOT NULL,
    waived boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: client_invoice_line_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_invoice_line_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_invoice_line_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_invoice_line_runs_id_seq OWNED BY public.client_invoice_line_runs.id;


--
-- Name: client_invoice_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_invoice_lines (
    id bigint NOT NULL,
    client_invoice_id bigint NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    source character varying DEFAULT 'manual'::character varying NOT NULL,
    trip_id bigint,
    ref character varying,
    description character varying NOT NULL,
    details text,
    period_text character varying,
    quantity numeric(10,2) DEFAULT 1.0 NOT NULL,
    unit_price numeric(12,2),
    amount numeric(12,2) DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT client_invoice_lines_source CHECK (((source)::text = ANY (ARRAY[('trip'::character varying)::text, ('late_cancel'::character varying)::text, ('manual'::character varying)::text])))
);


--
-- Name: client_invoice_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_invoice_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_invoice_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_invoice_lines_id_seq OWNED BY public.client_invoice_lines.id;


--
-- Name: client_invoice_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_invoice_payments (
    id bigint NOT NULL,
    client_invoice_id bigint NOT NULL,
    paid_on date NOT NULL,
    amount numeric(12,2) NOT NULL,
    method character varying NOT NULL,
    reference character varying,
    recorded_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT client_invoice_payments_amount CHECK ((amount > (0)::numeric))
);


--
-- Name: client_invoice_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_invoice_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_invoice_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_invoice_payments_id_seq OWNED BY public.client_invoice_payments.id;


--
-- Name: client_invoice_sends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_invoice_sends (
    id bigint NOT NULL,
    client_invoice_id bigint NOT NULL,
    to_emails character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    cc_emails character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    sent_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: client_invoice_sends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_invoice_sends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_invoice_sends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_invoice_sends_id_seq OWNED BY public.client_invoice_sends.id;


--
-- Name: client_invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_invoices (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    kind character varying DEFAULT 'invoice'::character varying NOT NULL,
    number character varying,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    client_id bigint NOT NULL,
    client_site_id bigint,
    invoice_id bigint,
    trip_id bigint,
    bill_to_name character varying,
    bill_to_uen character varying,
    bill_to_address text,
    attention character varying,
    po character varying,
    issued_on date,
    terms_days integer DEFAULT 30 NOT NULL,
    due_on date,
    period_from date,
    period_to date,
    gst_on boolean DEFAULT false NOT NULL,
    gst_rate numeric(5,2) DEFAULT 0.0 NOT NULL,
    gst_mode character varying DEFAULT 'excl'::character varying NOT NULL,
    subtotal numeric(12,2) DEFAULT 0.0 NOT NULL,
    gst numeric(12,2) DEFAULT 0.0 NOT NULL,
    total numeric(12,2) DEFAULT 0.0 NOT NULL,
    reason text,
    notes text,
    created_by_id bigint,
    issued_at timestamp(6) without time zone,
    issued_by_id bigint,
    voided_at timestamp(6) without time zone,
    voided_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT client_invoices_kind CHECK (((kind)::text = ANY (ARRAY[('invoice'::character varying)::text, ('credit_note'::character varying)::text]))),
    CONSTRAINT client_invoices_status CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('issued'::character varying)::text, ('void'::character varying)::text])))
);


--
-- Name: client_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_invoices_id_seq OWNED BY public.client_invoices.id;


--
-- Name: client_pickup_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_pickup_points (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    client_id bigint NOT NULL,
    name character varying NOT NULL,
    address text,
    postal_code character varying,
    lat numeric(10,7),
    lng numeric(10,7),
    note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    created_by_id bigint
);


--
-- Name: client_pickup_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_pickup_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_pickup_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_pickup_points_id_seq OWNED BY public.client_pickup_points.id;


--
-- Name: client_sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_sites (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    client_id bigint NOT NULL,
    name character varying NOT NULL,
    address text,
    lat numeric(10,7),
    lng numeric(10,7),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    school_id bigint,
    own_billing boolean DEFAULT false NOT NULL,
    billing_name character varying,
    billing_uen character varying,
    billing_address text,
    created_by_id bigint
);


--
-- Name: client_sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_sites_id_seq OWNED BY public.client_sites.id;


--
-- Name: client_user_sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_user_sites (
    id bigint NOT NULL,
    client_user_id bigint NOT NULL,
    client_site_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: client_user_sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_user_sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_user_sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_user_sites_id_seq OWNED BY public.client_user_sites.id;


--
-- Name: client_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_users (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    client_id bigint NOT NULL,
    portal_account_id bigint NOT NULL,
    name character varying NOT NULL,
    title character varying,
    email character varying NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    created_by_id bigint,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT client_users_role CHECK (((role)::text = ANY (ARRAY[('super'::character varying)::text, ('adm'::character varying)::text, ('fin'::character varying)::text, ('ssa'::character varying)::text, ('sa'::character varying)::text, ('sfin'::character varying)::text, ('member'::character varying)::text])))
);


--
-- Name: client_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_users_id_seq OWNED BY public.client_users.id;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    code character varying NOT NULL,
    kind character varying DEFAULT 'company'::character varying NOT NULL,
    name character varying NOT NULL,
    uen character varying,
    contact_name character varying,
    phone character varying,
    email character varying,
    billing_address text,
    on_time_allowance integer DEFAULT 3 NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    rate_card_id bigint,
    payment_terms_days integer,
    default_po character varying,
    late_cancel_hours integer DEFAULT 24 NOT NULL
);


--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clients_id_seq OWNED BY public.clients.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    name character varying NOT NULL,
    short_name character varying(12),
    code character varying(6) NOT NULL,
    country character varying DEFAULT 'SG'::character varying NOT NULL,
    timezone character varying DEFAULT 'Asia/Singapore'::character varying NOT NULL,
    theme_color character varying,
    logo character varying,
    date_format character varying DEFAULT 'dmy'::character varying NOT NULL,
    time_format character varying DEFAULT '24'::character varying NOT NULL,
    observed_holidays character varying DEFAULT 'off'::character varying NOT NULL,
    business_units_enabled boolean DEFAULT false NOT NULL,
    school_run_enabled boolean DEFAULT true NOT NULL,
    route_list_import_enabled boolean DEFAULT true NOT NULL,
    external_vehicle_cap integer DEFAULT 10 NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    on_time_minutes integer DEFAULT 5 NOT NULL,
    speed_limit_kmh integer DEFAULT 80 NOT NULL,
    country_set_at timestamp(6) without time zone,
    country_set_by_id bigint,
    stop_photo_auto_driver boolean DEFAULT false NOT NULL,
    stop_photo_auto_parent boolean DEFAULT false NOT NULL
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: company_country_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_country_requests (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    from_country character varying NOT NULL,
    to_country character varying NOT NULL,
    reason text NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    requested_by_id bigint,
    decided_by_id bigint,
    decided_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT company_country_requests_status CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('approved'::character varying)::text, ('declined'::character varying)::text, ('withdrawn'::character varying)::text])))
);


--
-- Name: company_country_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.company_country_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_country_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.company_country_requests_id_seq OWNED BY public.company_country_requests.id;


--
-- Name: company_lead_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_lead_domains (
    id bigint NOT NULL,
    domain character varying NOT NULL,
    status character varying DEFAULT 'new'::character varying NOT NULL,
    note text,
    updated_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT company_lead_domains_status CHECK (((status)::text = ANY (ARRAY[('new'::character varying)::text, ('contacted'::character varying)::text, ('demo'::character varying)::text, ('signed'::character varying)::text, ('lost'::character varying)::text])))
);


--
-- Name: company_lead_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.company_lead_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_lead_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.company_lead_domains_id_seq OWNED BY public.company_lead_domains.id;


--
-- Name: company_leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_leads (
    id bigint NOT NULL,
    domain character varying NOT NULL,
    company_name character varying NOT NULL,
    contact character varying,
    named_name character varying,
    named_via character varying,
    source character varying DEFAULT 'Convoy app'::character varying NOT NULL,
    asked_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: company_leads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.company_leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.company_leads_id_seq OWNED BY public.company_leads.id;


--
-- Name: company_sequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_sequences (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    value bigint DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: company_sequences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.company_sequences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_sequences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.company_sequences_id_seq OWNED BY public.company_sequences.id;


--
-- Name: dashboard_layouts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dashboard_layouts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint NOT NULL,
    pages jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dashboard_layouts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dashboard_layouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dashboard_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dashboard_layouts_id_seq OWNED BY public.dashboard_layouts.id;


--
-- Name: disabled_vehicle_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disabled_vehicle_types (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: disabled_vehicle_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disabled_vehicle_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disabled_vehicle_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disabled_vehicle_types_id_seq OWNED BY public.disabled_vehicle_types.id;


--
-- Name: discover_advertisers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discover_advertisers (
    id bigint NOT NULL,
    name character varying NOT NULL,
    kind character varying DEFAULT 'brand'::character varying NOT NULL,
    premier boolean DEFAULT false NOT NULL,
    country character varying DEFAULT 'SG'::character varying NOT NULL,
    listing_fee numeric(12,2) DEFAULT 0.0 NOT NULL,
    commission_pct numeric(5,2) DEFAULT 0.0 NOT NULL,
    email character varying,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT discover_advertisers_kind CHECK (((kind)::text = ANY (ARRAY[('tc'::character varying)::text, ('attr'::character varying)::text, ('prog'::character varying)::text, ('brand'::character varying)::text])))
);


--
-- Name: discover_advertisers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discover_advertisers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discover_advertisers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discover_advertisers_id_seq OWNED BY public.discover_advertisers.id;


--
-- Name: discover_placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discover_placements (
    id bigint NOT NULL,
    discover_advertiser_id bigint,
    kind character varying DEFAULT 'trip'::character varying NOT NULL,
    kicker character varying,
    title character varying NOT NULL,
    subtitle character varying,
    background character varying DEFAULT '#004F59'::character varying NOT NULL,
    image character varying,
    cta character varying DEFAULT 'Book Now'::character varying NOT NULL,
    price numeric(12,2),
    child_price numeric(12,2),
    seats integer,
    event_on date,
    pickup_points character varying,
    run_by_company_id bigint,
    bus_included boolean DEFAULT true NOT NULL,
    sold_to_public boolean DEFAULT false NOT NULL,
    link character varying,
    promo_code character varying,
    show_home boolean DEFAULT true NOT NULL,
    show_discover boolean DEFAULT true NOT NULL,
    push_once boolean DEFAULT false NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    slot character varying DEFAULT 'std'::character varying NOT NULL,
    audiences character varying[] DEFAULT '{parents}'::character varying[] NOT NULL,
    area character varying DEFAULT 'all'::character varying NOT NULL,
    school_level character varying DEFAULT 'any'::character varying NOT NULL,
    listing_fee numeric(12,2) DEFAULT 0.0 NOT NULL,
    commission_pct numeric(5,2) DEFAULT 0.0 NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    ended_at timestamp(6) without time zone,
    views integer DEFAULT 0 NOT NULL,
    taps integer DEFAULT 0 NOT NULL,
    sold integer DEFAULT 0 NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT discover_placements_kind CHECK (((kind)::text = ANY (ARRAY[('trip'::character varying)::text, ('prog'::character varying)::text, ('ad'::character varying)::text, ('news'::character varying)::text]))),
    CONSTRAINT discover_placements_status CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('live'::character varying)::text, ('paused'::character varying)::text])))
);


--
-- Name: discover_placements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discover_placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discover_placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discover_placements_id_seq OWNED BY public.discover_placements.id;


--
-- Name: document_reads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_reads (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint,
    kind character varying NOT NULL,
    file character varying,
    input_text text,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    result jsonb,
    error text,
    model character varying,
    input_tokens integer,
    output_tokens integer,
    finished_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: document_reads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.document_reads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_reads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.document_reads_id_seq OWNED BY public.document_reads.id;


--
-- Name: driver_app_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_app_sessions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    driver_id bigint,
    operator_driver_id bigint,
    tracking_device_id bigint,
    signed_in_at timestamp with time zone NOT NULL,
    signed_out_at timestamp with time zone,
    last_seen_at timestamp with time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT driver_app_sessions_one_driver CHECK ((num_nonnulls(driver_id, operator_driver_id) = 1))
);


--
-- Name: driver_app_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_app_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_app_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_app_sessions_id_seq OWNED BY public.driver_app_sessions.id;


--
-- Name: driver_invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_invites (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    invitable_type character varying NOT NULL,
    invitable_id bigint NOT NULL,
    kind character varying DEFAULT 'invite'::character varying NOT NULL,
    phone character varying NOT NULL,
    message text NOT NULL,
    delivery character varying DEFAULT 'recorded'::character varying NOT NULL,
    sent_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT driver_invites_kind CHECK (((kind)::text = ANY (ARRAY[('invite'::character varying)::text, ('resend'::character varying)::text])))
);


--
-- Name: driver_invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_invites_id_seq OWNED BY public.driver_invites.id;


--
-- Name: driver_kyc_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_kyc_profiles (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    driver_type character varying NOT NULL,
    driver_id bigint NOT NULL,
    email character varying,
    address text,
    date_of_birth date,
    nationality character varying,
    residential_status character varying,
    id_number character varying,
    id_number_masked character varying,
    licence_class character varying,
    licence_qualified_on date,
    vocational_licence_number character varying,
    vocational_licence_expires_on date,
    shared_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: driver_kyc_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_kyc_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_kyc_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_kyc_profiles_id_seq OWNED BY public.driver_kyc_profiles.id;


--
-- Name: driver_pay_month_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_pay_month_lines (
    id bigint NOT NULL,
    driver_pay_month_id bigint NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    part_from date,
    part_to date,
    scheme_name character varying,
    label character varying NOT NULL,
    amount numeric(12,2),
    text character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: driver_pay_month_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_pay_month_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_pay_month_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_pay_month_lines_id_seq OWNED BY public.driver_pay_month_lines.id;


--
-- Name: driver_pay_month_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_pay_month_runs (
    id bigint NOT NULL,
    driver_pay_month_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    trip_label character varying,
    trip_value numeric(10,2),
    hours numeric(6,2),
    amount numeric(12,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: driver_pay_month_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_pay_month_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_pay_month_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_pay_month_runs_id_seq OWNED BY public.driver_pay_month_runs.id;


--
-- Name: driver_pay_months; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_pay_months (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    month date NOT NULL,
    total numeric(12,2) NOT NULL,
    trips numeric(10,2) DEFAULT 0.0 NOT NULL,
    runs_count integer DEFAULT 0 NOT NULL,
    confirmed_by_id bigint,
    confirmed_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: driver_pay_months_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_pay_months_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_pay_months_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_pay_months_id_seq OWNED BY public.driver_pay_months.id;


--
-- Name: driver_pay_schemes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_pay_schemes (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    pay_scheme_id bigint NOT NULL,
    starts_on date NOT NULL,
    ends_on date,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: driver_pay_schemes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_pay_schemes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_pay_schemes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_pay_schemes_id_seq OWNED BY public.driver_pay_schemes.id;


--
-- Name: driver_point_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_point_allocations (
    id bigint NOT NULL,
    driver_point_deduction_id bigint NOT NULL,
    driver_point_lot_id bigint NOT NULL,
    points integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: driver_point_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_point_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_point_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_point_allocations_id_seq OWNED BY public.driver_point_allocations.id;


--
-- Name: driver_point_deductions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_point_deductions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    points integer NOT NULL,
    reason character varying NOT NULL,
    deducted_on date NOT NULL,
    deducted_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT driver_point_deductions_points CHECK ((points > 0))
);


--
-- Name: driver_point_deductions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_point_deductions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_point_deductions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_point_deductions_id_seq OWNED BY public.driver_point_deductions.id;


--
-- Name: driver_point_lots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_point_lots (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    points integer NOT NULL,
    remaining integer NOT NULL,
    source character varying DEFAULT 'manual'::character varying NOT NULL,
    reason character varying NOT NULL,
    awarded_on date NOT NULL,
    expires_on date NOT NULL,
    awarded_by_id bigint,
    pay_bonus_id bigint,
    driver_pay_month_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT driver_point_lots_points CHECK (((points > 0) AND ((remaining >= 0) AND (remaining <= points)))),
    CONSTRAINT driver_point_lots_source CHECK (((source)::text = ANY (ARRAY[('manual'::character varying)::text, ('bonus'::character varying)::text])))
);


--
-- Name: driver_point_lots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_point_lots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_point_lots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_point_lots_id_seq OWNED BY public.driver_point_lots.id;


--
-- Name: driver_vehicle_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_vehicle_types (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    starts_on date NOT NULL,
    ends_on date,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: driver_vehicle_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_vehicle_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_vehicle_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_vehicle_types_id_seq OWNED BY public.driver_vehicle_types.id;


--
-- Name: drivers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drivers (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    phone character varying NOT NULL,
    photo character varying,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    invited_at timestamp(6) without time zone,
    responded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_vehicle_id bigint,
    display_name character varying,
    display_photo character varying,
    display_set_by_id bigint,
    display_set_at timestamp(6) without time zone,
    discarded_at timestamp(6) without time zone
);


--
-- Name: drivers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: drivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.drivers_id_seq OWNED BY public.drivers.id;


--
-- Name: external_vehicle_share_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_vehicle_share_links (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    token character varying NOT NULL,
    created_by_id bigint,
    revoked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: external_vehicle_share_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_vehicle_share_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_vehicle_share_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_vehicle_share_links_id_seq OWNED BY public.external_vehicle_share_links.id;


--
-- Name: external_vehicle_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_vehicle_submissions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    share_link_id bigint NOT NULL,
    plate character varying NOT NULL,
    seats integer,
    driver_name character varying NOT NULL,
    driver_phone character varying NOT NULL,
    company_name character varying NOT NULL,
    company_phone character varying,
    paynow character varying,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    vehicle_id bigint,
    decided_by_id bigint,
    decided_at timestamp(6) without time zone,
    submitted_ip character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT external_vehicle_submissions_status CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('added'::character varying)::text, ('dismissed'::character varying)::text])))
);


--
-- Name: external_vehicle_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_vehicle_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_vehicle_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_vehicle_submissions_id_seq OWNED BY public.external_vehicle_submissions.id;


--
-- Name: families; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.families (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    name_mode character varying DEFAULT 'auto'::character varying NOT NULL,
    source character varying DEFAULT 'console'::character varying NOT NULL,
    address text,
    postal character varying,
    registered_at timestamp with time zone,
    sample boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: families_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.families_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: families_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.families_id_seq OWNED BY public.families.id;


--
-- Name: family_guardians; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_guardians (
    id bigint NOT NULL,
    family_id bigint NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    first_name character varying,
    last_name character varying,
    name_order character varying DEFAULT 'last'::character varying NOT NULL,
    relationship character varying DEFAULT 'Parent'::character varying NOT NULL,
    phone character varying,
    email character varying,
    app_joined_at timestamp with time zone,
    app_joined_how character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: family_guardians_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.family_guardians_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: family_guardians_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.family_guardians_id_seq OWNED BY public.family_guardians.id;


--
-- Name: family_riders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.family_riders (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    family_id bigint NOT NULL,
    school_id bigint NOT NULL,
    rid character varying NOT NULL,
    applied_at timestamp with time zone,
    accepted_at timestamp with time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: family_riders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.family_riders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: family_riders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.family_riders_id_seq OWNED BY public.family_riders.id;


--
-- Name: fare_adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_adjustments (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    name character varying NOT NULL,
    kind character varying NOT NULL,
    value numeric(12,2) NOT NULL,
    from_month date NOT NULL,
    to_month date,
    targets character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    note character varying,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: fare_adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fare_adjustments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fare_adjustments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fare_adjustments_id_seq OWNED BY public.fare_adjustments.id;


--
-- Name: fare_bus_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_bus_rates (
    id bigint NOT NULL,
    fare_table_id bigint NOT NULL,
    bus_type character varying NOT NULL,
    rate numeric(12,2) NOT NULL,
    booked_runs integer
);


--
-- Name: fare_bus_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fare_bus_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fare_bus_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fare_bus_rates_id_seq OWNED BY public.fare_bus_rates.id;


--
-- Name: fare_size_columns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_size_columns (
    id bigint NOT NULL,
    fare_table_id bigint NOT NULL,
    "position" integer NOT NULL,
    max_seats integer
);


--
-- Name: fare_size_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fare_size_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fare_size_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fare_size_columns_id_seq OWNED BY public.fare_size_columns.id;


--
-- Name: fare_surcharges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_surcharges (
    id bigint NOT NULL,
    fare_table_id bigint NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    sectors character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    area jsonb,
    kind character varying DEFAULT 'flat'::character varying NOT NULL,
    amount numeric(12,2),
    one_way_kind character varying DEFAULT 'same'::character varying NOT NULL,
    one_way_value numeric(12,2)
);


--
-- Name: fare_surcharges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fare_surcharges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fare_surcharges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fare_surcharges_id_seq OWNED BY public.fare_surcharges.id;


--
-- Name: fare_tables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_tables (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    payer character varying DEFAULT 'parents'::character varying NOT NULL,
    bill_to_name character varying,
    bill_to_contact character varying,
    bill_to_email character varying,
    basis character varying DEFAULT 'distance'::character varying NOT NULL,
    trip character varying DEFAULT 'both'::character varying NOT NULL,
    cycle character varying DEFAULT 'period'::character varying NOT NULL,
    months integer[] DEFAULT '{1,2,3,4,5,6,7,8,9,10,11,12}'::integer[] NOT NULL,
    distribution character varying DEFAULT 'equal'::character varying NOT NULL,
    one_way_type character varying DEFAULT 'pct'::character varying NOT NULL,
    one_way_value numeric(12,2),
    by_size boolean DEFAULT false NOT NULL,
    small_on boolean DEFAULT false NOT NULL,
    small_type character varying DEFAULT 'pct'::character varying NOT NULL,
    small_value numeric(12,2),
    small_seats integer DEFAULT 15 NOT NULL,
    express_on boolean DEFAULT false NOT NULL,
    express_type character varying DEFAULT 'pct'::character varying NOT NULL,
    express_value numeric(12,2),
    cca_on boolean DEFAULT false NOT NULL,
    cca_per character varying DEFAULT 'trip'::character varying NOT NULL,
    cca_price character varying DEFAULT 'fixed'::character varying NOT NULL,
    cca_fixed numeric(12,2),
    cca_split character varying DEFAULT 'equal'::character varying NOT NULL,
    cca_with_services boolean DEFAULT false NOT NULL,
    cca_non_on boolean DEFAULT false NOT NULL,
    cca_non_type character varying DEFAULT 'pct'::character varying NOT NULL,
    cca_non_amount numeric(12,2),
    cca_am_on boolean DEFAULT false NOT NULL,
    cca_am_type character varying DEFAULT 'pct'::character varying NOT NULL,
    cca_am_amount numeric(12,2),
    cca_pm_on boolean DEFAULT false NOT NULL,
    cca_pm_type character varying DEFAULT 'pct'::character varying NOT NULL,
    cca_pm_amount numeric(12,2),
    bus_count character varying DEFAULT 'plan'::character varying NOT NULL,
    period_snapshot jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: fare_tables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fare_tables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fare_tables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fare_tables_id_seq OWNED BY public.fare_tables.id;


--
-- Name: fare_tier_sizes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_tier_sizes (
    id bigint NOT NULL,
    fare_tier_id bigint NOT NULL,
    fare_size_column_id bigint NOT NULL,
    fare numeric(12,2),
    pm_fare numeric(12,2),
    one_way_fare numeric(12,2),
    period_fares numeric(12,2)[] DEFAULT '{}'::numeric[] NOT NULL,
    period_pm_fares numeric(12,2)[] DEFAULT '{}'::numeric[] NOT NULL
);


--
-- Name: fare_tier_sizes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fare_tier_sizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fare_tier_sizes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fare_tier_sizes_id_seq OWNED BY public.fare_tier_sizes.id;


--
-- Name: fare_tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_tiers (
    id bigint NOT NULL,
    fare_table_id bigint NOT NULL,
    "position" integer NOT NULL,
    max_km numeric(6,2),
    name character varying,
    sectors character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    area jsonb,
    fare numeric(12,2),
    pm_fare numeric(12,2),
    one_way_fare numeric(12,2),
    period_fares numeric(12,2)[] DEFAULT '{}'::numeric[] NOT NULL,
    period_pm_fares numeric(12,2)[] DEFAULT '{}'::numeric[] NOT NULL,
    small_fare numeric(12,2),
    express_fare numeric(12,2),
    cca_fare numeric(12,2)
);


--
-- Name: fare_tiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fare_tiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fare_tiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fare_tiers_id_seq OWNED BY public.fare_tiers.id;


--
-- Name: feasibility_bus_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feasibility_bus_prices (
    id bigint NOT NULL,
    feasibility_study_id bigint NOT NULL,
    bus_type character varying NOT NULL,
    monthly numeric(12,2),
    attendant numeric(12,2)
);


--
-- Name: feasibility_bus_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feasibility_bus_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feasibility_bus_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feasibility_bus_prices_id_seq OWNED BY public.feasibility_bus_prices.id;


--
-- Name: feasibility_fare_tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feasibility_fare_tiers (
    id bigint NOT NULL,
    feasibility_study_id bigint NOT NULL,
    "position" integer NOT NULL,
    max_km numeric(6,2),
    fare numeric(12,2),
    one_way_fare numeric(12,2)
);


--
-- Name: feasibility_fare_tiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feasibility_fare_tiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feasibility_fare_tiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feasibility_fare_tiers_id_seq OWNED BY public.feasibility_fare_tiers.id;


--
-- Name: feasibility_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feasibility_rows (
    id bigint NOT NULL,
    feasibility_study_id bigint NOT NULL,
    postal character varying NOT NULL,
    riders integer DEFAULT 1 NOT NULL,
    session character varying DEFAULT 'both'::character varying NOT NULL,
    level character varying
);


--
-- Name: feasibility_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feasibility_rows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feasibility_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feasibility_rows_id_seq OWNED BY public.feasibility_rows.id;


--
-- Name: feasibility_scenarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feasibility_scenarios (
    id bigint NOT NULL,
    feasibility_study_id bigint NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    sizes character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    attendant character varying DEFAULT 'STATUTORY'::character varying NOT NULL,
    hard_cap integer DEFAULT 75 NOT NULL,
    target_cap integer DEFAULT 50 NOT NULL,
    margin_pct numeric(5,2) DEFAULT 30.0 NOT NULL,
    extra_buses jsonb DEFAULT '{}'::jsonb NOT NULL,
    params jsonb DEFAULT '{}'::jsonb NOT NULL,
    status character varying DEFAULT 'idle'::character varying NOT NULL,
    result jsonb,
    stale boolean DEFAULT false NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: feasibility_scenarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feasibility_scenarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feasibility_scenarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feasibility_scenarios_id_seq OWNED BY public.feasibility_scenarios.id;


--
-- Name: feasibility_studies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feasibility_studies (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    school_mode character varying DEFAULT 'prospect'::character varying NOT NULL,
    school_id bigint,
    prospect_name character varying,
    prospect_postal character varying,
    prospect_lat numeric(10,7),
    prospect_lng numeric(10,7),
    pickup character varying DEFAULT 'door'::character varying NOT NULL,
    walk_m integer DEFAULT 400 NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: feasibility_studies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feasibility_studies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feasibility_studies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feasibility_studies_id_seq OWNED BY public.feasibility_studies.id;


--
-- Name: finance_approvers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.finance_approvers (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint NOT NULL,
    can_prepare boolean DEFAULT true NOT NULL,
    can_approve boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: finance_approvers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.finance_approvers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: finance_approvers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.finance_approvers_id_seq OWNED BY public.finance_approvers.id;


--
-- Name: finance_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.finance_settings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    gst_on boolean DEFAULT false NOT NULL,
    gst_rate numeric(5,2) DEFAULT 9.0 NOT NULL,
    gst_mode character varying DEFAULT 'excl'::character varying NOT NULL,
    gst_reg_no character varying,
    approval character varying DEFAULT 'single'::character varying NOT NULL,
    brand_name character varying,
    brand_uen character varying,
    brand_address text,
    brand_phone character varying,
    brand_email character varying,
    brand_note character varying DEFAULT 'Thank you for riding with us.'::character varying,
    bank_id bigint,
    account_number character varying,
    account_name character varying,
    paynow character varying,
    payment_note character varying DEFAULT 'Please pay by the due date and quote the invoice number.'::character varying,
    prefix_inv character varying DEFAULT 'INV'::character varying NOT NULL,
    prefix_cn character varying DEFAULT 'CN'::character varying NOT NULL,
    prefix_dn character varying DEFAULT 'DN'::character varying NOT NULL,
    prefix_rcp character varying DEFAULT 'RCP'::character varying NOT NULL,
    prefix_pv character varying DEFAULT 'PV'::character varying NOT NULL,
    prefix_pn character varying DEFAULT 'PN'::character varying NOT NULL,
    prefix_pb character varying DEFAULT 'PB'::character varying NOT NULL,
    locked_at timestamp(6) without time zone,
    locked_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT finance_settings_approval CHECK (((approval)::text = ANY (ARRAY[('single'::character varying)::text, ('maker'::character varying)::text]))),
    CONSTRAINT finance_settings_gst_mode CHECK (((gst_mode)::text = ANY (ARRAY[('excl'::character varying)::text, ('incl'::character varying)::text])))
);


--
-- Name: finance_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.finance_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: finance_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.finance_settings_id_seq OWNED BY public.finance_settings.id;


--
-- Name: fuel_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fuel_alerts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    fuel_entry_id bigint,
    key character varying NOT NULL,
    kind character varying NOT NULL,
    tone character varying DEFAULT 'warn'::character varying NOT NULL,
    metric character varying,
    message text NOT NULL,
    date date NOT NULL,
    status character varying DEFAULT 'open'::character varying NOT NULL,
    checked_by_id bigint,
    checked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT fuel_alerts_kind CHECK (((kind)::text = ANY (ARRAY[('eff'::character varying)::text, ('odo'::character varying)::text, ('dbl'::character varying)::text, ('big'::character varying)::text, ('price'::character varying)::text, ('trend'::character varying)::text]))),
    CONSTRAINT fuel_alerts_status CHECK (((status)::text = ANY (ARRAY[('open'::character varying)::text, ('checked'::character varying)::text])))
);


--
-- Name: fuel_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fuel_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fuel_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fuel_alerts_id_seq OWNED BY public.fuel_alerts.id;


--
-- Name: fuel_companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fuel_companies (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    kind character varying DEFAULT 'fuel'::character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT fuel_companies_kind CHECK (((kind)::text = ANY (ARRAY[('fuel'::character varying)::text, ('elec'::character varying)::text, ('both'::character varying)::text])))
);


--
-- Name: fuel_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fuel_companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fuel_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fuel_companies_id_seq OWNED BY public.fuel_companies.id;


--
-- Name: fuel_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fuel_entries (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    driver_id bigint,
    date date NOT NULL,
    "time" integer,
    kind character varying NOT NULL,
    quantity numeric(10,2) NOT NULL,
    cost numeric(12,2) NOT NULL,
    odometer integer,
    "full" boolean DEFAULT true NOT NULL,
    fuel_company_id bigint,
    station character varying,
    note text,
    receipt character varying,
    document_read_id bigint,
    created_by_id bigint,
    km_since integer,
    efficiency numeric(7,1),
    odometer_back integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    energy_km integer,
    CONSTRAINT fuel_entries_amounts CHECK (((quantity > (0)::numeric) AND (cost >= (0)::numeric))),
    CONSTRAINT fuel_entries_kind CHECK (((kind)::text = ANY (ARRAY[('diesel'::character varying)::text, ('petrol'::character varying)::text, ('def'::character varying)::text, ('elec'::character varying)::text])))
);


--
-- Name: fuel_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fuel_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fuel_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fuel_entries_id_seq OWNED BY public.fuel_entries.id;


--
-- Name: maintenance_invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_invoices (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    maintenance_visit_id bigint NOT NULL,
    file character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: maintenance_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance_invoices_id_seq OWNED BY public.maintenance_invoices.id;


--
-- Name: maintenance_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_lines (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    maintenance_visit_id bigint NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    line_type character varying DEFAULT 'part'::character varying NOT NULL,
    description character varying,
    part_number character varying,
    brand character varying,
    model character varying,
    tyre_position character varying,
    quantity numeric(10,2) DEFAULT 1.0 NOT NULL,
    unit_price numeric(12,2) DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: maintenance_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance_lines_id_seq OWNED BY public.maintenance_lines.id;


--
-- Name: maintenance_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_visits (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    driver_id bigint,
    date date NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    workshop_id bigint,
    address text,
    kind character varying DEFAULT 'service'::character varying NOT NULL,
    work_to_do text,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    odometer integer,
    gst_on boolean DEFAULT true NOT NULL,
    gst_rate numeric(5,2) DEFAULT 9.0 NOT NULL,
    driver_notified_at timestamp(6) without time zone,
    completed_by_id bigint,
    completed_at timestamp(6) without time zone,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: maintenance_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance_visits_id_seq OWNED BY public.maintenance_visits.id;


--
-- Name: message_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_terms (
    id bigint NOT NULL,
    term character varying NOT NULL,
    means text NOT NULL,
    kind character varying DEFAULT 'oth'::character varying NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: message_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_terms_id_seq OWNED BY public.message_terms.id;


--
-- Name: notice_deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notice_deliveries (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    notice_id bigint NOT NULL,
    channel character varying NOT NULL,
    recipients integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notice_deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notice_deliveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notice_deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notice_deliveries_id_seq OWNED BY public.notice_deliveries.id;


--
-- Name: notice_routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notice_routes (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    notice_id bigint NOT NULL,
    school_route_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notice_routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notice_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notice_routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notice_routes_id_seq OWNED BY public.notice_routes.id;


--
-- Name: notice_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notice_runs (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    notice_id bigint NOT NULL,
    trip_run_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notice_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notice_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notice_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notice_runs_id_seq OWNED BY public.notice_runs.id;


--
-- Name: notice_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notice_templates (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    message text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notice_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notice_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notice_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notice_templates_id_seq OWNED BY public.notice_templates.id;


--
-- Name: notices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notices (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    audience character varying DEFAULT 'trip'::character varying NOT NULL,
    trip_id bigint,
    all_runs boolean DEFAULT true NOT NULL,
    to_riders boolean DEFAULT true NOT NULL,
    to_parents boolean DEFAULT false NOT NULL,
    banner boolean DEFAULT true NOT NULL,
    push boolean DEFAULT false NOT NULL,
    sms boolean DEFAULT false NOT NULL,
    starts_at timestamp(6) without time zone NOT NULL,
    ends_at timestamp(6) without time zone NOT NULL,
    notice_template_id bigint,
    message character varying(300) NOT NULL,
    ended_at timestamp(6) without time zone,
    ended_by_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    school_id bigint,
    CONSTRAINT notices_period CHECK ((ends_at > starts_at))
);


--
-- Name: notices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notices_id_seq OWNED BY public.notices.id;


--
-- Name: notification_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_emails (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint NOT NULL,
    booking_event_id bigint,
    "to" character varying NOT NULL,
    subject character varying NOT NULL,
    body text,
    sent_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notification_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_emails_id_seq OWNED BY public.notification_emails.id;


--
-- Name: occurrence_correction_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_correction_logs (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_correction_id bigint NOT NULL,
    user_id bigint,
    reason text NOT NULL,
    items text[] DEFAULT '{}'::text[] NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: occurrence_correction_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.occurrence_correction_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrence_correction_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.occurrence_correction_logs_id_seq OWNED BY public.occurrence_correction_logs.id;


--
-- Name: occurrence_correction_stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_correction_stops (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_correction_id bigint NOT NULL,
    "position" integer NOT NULL,
    stop_name character varying,
    arrived_at integer,
    departed_at integer,
    boarded integer,
    alighted integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: occurrence_correction_stops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.occurrence_correction_stops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrence_correction_stops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.occurrence_correction_stops_id_seq OWNED BY public.occurrence_correction_stops.id;


--
-- Name: occurrence_corrections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_corrections (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    outcome character varying,
    vehicle_id bigint,
    vehicle_plate character varying,
    driver_id bigint,
    driver_name character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT occurrence_corrections_outcome CHECK (((outcome)::text = ANY (ARRAY[('completed'::character varying)::text, ('incomplete'::character varying)::text])))
);


--
-- Name: occurrence_corrections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.occurrence_corrections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrence_corrections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.occurrence_corrections_id_seq OWNED BY public.occurrence_corrections.id;


--
-- Name: occurrence_driver_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_driver_reports (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    driver_name character varying,
    note text,
    submitted_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: occurrence_driver_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.occurrence_driver_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrence_driver_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.occurrence_driver_reports_id_seq OWNED BY public.occurrence_driver_reports.id;


--
-- Name: occurrence_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_notes (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    body text NOT NULL,
    author_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: occurrence_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.occurrence_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrence_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.occurrence_notes_id_seq OWNED BY public.occurrence_notes.id;


--
-- Name: occurrence_positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_positions (
    id bigint NOT NULL,
    occurrence_date date NOT NULL,
    occurrence_id bigint NOT NULL,
    company_id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint
)
PARTITION BY RANGE (occurrence_date);


--
-- Name: occurrence_positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.occurrence_positions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.occurrence_positions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: occurrence_positions_y2026m09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_positions_y2026m09 (
    id bigint NOT NULL,
    occurrence_date date NOT NULL,
    occurrence_id bigint NOT NULL,
    company_id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint
);


--
-- Name: occurrence_positions_y2026m10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_positions_y2026m10 (
    id bigint NOT NULL,
    occurrence_date date NOT NULL,
    occurrence_id bigint NOT NULL,
    company_id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint
);


--
-- Name: occurrence_positions_y2026m11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_positions_y2026m11 (
    id bigint NOT NULL,
    occurrence_date date NOT NULL,
    occurrence_id bigint NOT NULL,
    company_id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint
);


--
-- Name: occurrence_positions_y2026m12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_positions_y2026m12 (
    id bigint NOT NULL,
    occurrence_date date NOT NULL,
    occurrence_id bigint NOT NULL,
    company_id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint
);


--
-- Name: occurrence_positions_y2027m01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_positions_y2027m01 (
    id bigint NOT NULL,
    occurrence_date date NOT NULL,
    occurrence_id bigint NOT NULL,
    company_id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint
);


--
-- Name: occurrence_positions_y2027m02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_positions_y2027m02 (
    id bigint NOT NULL,
    occurrence_date date NOT NULL,
    occurrence_id bigint NOT NULL,
    company_id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint
);


--
-- Name: occurrence_positions_y2027m03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_positions_y2027m03 (
    id bigint NOT NULL,
    occurrence_date date NOT NULL,
    occurrence_id bigint NOT NULL,
    company_id bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint
);


--
-- Name: occurrence_report_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_report_photos (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_driver_report_id bigint NOT NULL,
    image character varying NOT NULL,
    caption character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: occurrence_report_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.occurrence_report_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrence_report_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.occurrence_report_photos_id_seq OWNED BY public.occurrence_report_photos.id;


--
-- Name: occurrence_stop_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_stop_events (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    "position" integer NOT NULL,
    stop_name character varying,
    arrived_at timestamp(6) without time zone,
    departed_at timestamp(6) without time zone,
    skipped boolean DEFAULT false NOT NULL,
    boarded integer,
    alighted integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: occurrence_stop_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.occurrence_stop_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrence_stop_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.occurrence_stop_events_id_seq OWNED BY public.occurrence_stop_events.id;


--
-- Name: occurrence_trip_summaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.occurrence_trip_summaries (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    started_at timestamp(6) without time zone,
    ended_at timestamp(6) without time zone,
    distance_km numeric(8,2),
    odometer_start_km integer,
    odometer_end_km integer,
    idle_seconds integer,
    max_speed_kmh numeric(5,1),
    avg_moving_speed_kmh numeric(5,1),
    overspeed_seconds integer,
    speed_limit_kmh integer,
    harsh_events integer,
    ping_count integer,
    ping_interval_seconds integer,
    fuel_used numeric(8,2),
    fuel_unit character varying,
    fuel_estimated boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: occurrence_trip_summaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.occurrence_trip_summaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occurrence_trip_summaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.occurrence_trip_summaries_id_seq OWNED BY public.occurrence_trip_summaries.id;


--
-- Name: operator_cost_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_cost_overrides (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    amount numeric(12,2) NOT NULL,
    set_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: operator_cost_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_cost_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_cost_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_cost_overrides_id_seq OWNED BY public.operator_cost_overrides.id;


--
-- Name: operator_drivers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_drivers (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    operator_id bigint NOT NULL,
    vehicle_id bigint,
    name character varying NOT NULL,
    phone character varying NOT NULL,
    photo character varying,
    notes text,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    invited_at timestamp(6) without time zone,
    responded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_vehicle_id bigint,
    display_name character varying,
    display_photo character varying,
    display_set_by_id bigint,
    display_set_at timestamp(6) without time zone,
    discarded_at timestamp(6) without time zone
);


--
-- Name: operator_drivers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_drivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_drivers_id_seq OWNED BY public.operator_drivers.id;


--
-- Name: operator_pay_batch_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_pay_batch_lines (
    id bigint NOT NULL,
    operator_pay_batch_operator_id bigint NOT NULL,
    ref character varying NOT NULL,
    source character varying NOT NULL,
    description character varying NOT NULL,
    details character varying,
    item_on date,
    amount numeric(12,2) NOT NULL,
    approved_by_id bigint,
    approved_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: operator_pay_batch_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_pay_batch_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_pay_batch_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_pay_batch_lines_id_seq OWNED BY public.operator_pay_batch_lines.id;


--
-- Name: operator_pay_batch_operators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_pay_batch_operators (
    id bigint NOT NULL,
    operator_pay_batch_id bigint NOT NULL,
    operator_id bigint NOT NULL,
    notice_number character varying,
    pay_method character varying,
    pay_to character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: operator_pay_batch_operators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_pay_batch_operators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_pay_batch_operators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_pay_batch_operators_id_seq OWNED BY public.operator_pay_batch_operators.id;


--
-- Name: operator_pay_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_pay_batches (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    number character varying NOT NULL,
    kind character varying DEFAULT 'batch'::character varying NOT NULL,
    pay_date date NOT NULL,
    transfer_type character varying,
    bank_file_at timestamp(6) without time zone,
    bank_file_by_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT operator_pay_batches_kind CHECK (((kind)::text = ANY (ARRAY[('batch'::character varying)::text, ('adhoc'::character varying)::text])))
);


--
-- Name: operator_pay_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_pay_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_pay_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_pay_batches_id_seq OWNED BY public.operator_pay_batches.id;


--
-- Name: operator_pay_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_pay_items (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    operator_id bigint NOT NULL,
    description character varying NOT NULL,
    item_on date NOT NULL,
    amount numeric(12,2) NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: operator_pay_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_pay_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_pay_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_pay_items_id_seq OWNED BY public.operator_pay_items.id;


--
-- Name: operator_pay_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_pay_payments (
    id bigint NOT NULL,
    operator_pay_batch_operator_id bigint NOT NULL,
    paid_on date NOT NULL,
    amount numeric(12,2) NOT NULL,
    method character varying NOT NULL,
    reference character varying,
    recorded_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: operator_pay_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_pay_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_pay_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_pay_payments_id_seq OWNED BY public.operator_pay_payments.id;


--
-- Name: operators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operators (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    kind character varying DEFAULT 'managed'::character varying NOT NULL,
    uen character varying,
    contact_name character varying,
    phone character varying,
    email character varying,
    payment_method character varying,
    paynow_uen character varying,
    bank_code character varying,
    branch_code character varying,
    account_number character varying,
    account_name character varying,
    valid_until date,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    bank_id bigint,
    cost_per_trip numeric(12,2),
    cost_per_day numeric(12,2)
);


--
-- Name: operators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operators_id_seq OWNED BY public.operators.id;


--
-- Name: ops_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ops_alerts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    occurrence_id bigint NOT NULL,
    occurrence_date date NOT NULL,
    kind character varying NOT NULL,
    severity smallint NOT NULL,
    message text NOT NULL,
    raised_at timestamp with time zone NOT NULL,
    cleared_at timestamp with time zone,
    acknowledged_at timestamp with time zone,
    acknowledged_by_id bigint,
    escalated_at timestamp with time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ops_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ops_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ops_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ops_alerts_id_seq OWNED BY public.ops_alerts.id;


--
-- Name: pay_bonus_drivers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_bonus_drivers (
    id bigint NOT NULL,
    pay_bonus_id bigint NOT NULL,
    driver_id bigint NOT NULL,
    role character varying NOT NULL,
    signed_up_at timestamp(6) without time zone,
    signed_up_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT pay_bonus_drivers_role CHECK (((role)::text = ANY (ARRAY[('eligible'::character varying)::text, ('signed_up'::character varying)::text])))
);


--
-- Name: pay_bonus_drivers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_bonus_drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_bonus_drivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_bonus_drivers_id_seq OWNED BY public.pay_bonus_drivers.id;


--
-- Name: pay_bonus_excluded_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_bonus_excluded_periods (
    id bigint NOT NULL,
    pay_bonus_id bigint NOT NULL,
    name character varying,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_bonus_excluded_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_bonus_excluded_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_bonus_excluded_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_bonus_excluded_periods_id_seq OWNED BY public.pay_bonus_excluded_periods.id;


--
-- Name: pay_bonus_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_bonus_payments (
    id bigint NOT NULL,
    pay_bonus_id bigint NOT NULL,
    percentage integer NOT NULL,
    months_after integer DEFAULT 1 NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_bonus_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_bonus_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_bonus_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_bonus_payments_id_seq OWNED BY public.pay_bonus_payments.id;


--
-- Name: pay_bonus_schemes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_bonus_schemes (
    id bigint NOT NULL,
    pay_bonus_id bigint NOT NULL,
    pay_scheme_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_bonus_schemes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_bonus_schemes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_bonus_schemes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_bonus_schemes_id_seq OWNED BY public.pay_bonus_schemes.id;


--
-- Name: pay_bonus_tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_bonus_tiers (
    id bigint NOT NULL,
    pay_bonus_id bigint NOT NULL,
    target_trips integer,
    metric_min numeric(5,2),
    metric_max numeric(5,2),
    pay_as character varying DEFAULT 'lump_sum'::character varying NOT NULL,
    amount numeric(12,2) DEFAULT 0.0 NOT NULL,
    points integer,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_bonus_tiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_bonus_tiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_bonus_tiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_bonus_tiers_id_seq OWNED BY public.pay_bonus_tiers.id;


--
-- Name: pay_bonuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_bonuses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    plan_type character varying DEFAULT 'trip_target'::character varying NOT NULL,
    frequency character varying DEFAULT 'monthly'::character varying NOT NULL,
    starts_on date NOT NULL,
    last_period_on date,
    payout_type character varying DEFAULT 'end_of_period'::character varying NOT NULL,
    payout_delay_months integer DEFAULT 1 NOT NULL,
    all_schemes boolean DEFAULT true NOT NULL,
    requires_sign_up boolean DEFAULT false NOT NULL,
    sign_up_from date,
    sign_up_to date,
    terms text,
    overlap_daily character varying DEFAULT 'additive'::character varying NOT NULL,
    overlap_weekly character varying DEFAULT 'additive'::character varying NOT NULL,
    overlap_monthly character varying DEFAULT 'additive'::character varying NOT NULL,
    locked_at timestamp(6) without time zone,
    locked_by_id bigint,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT pay_bonuses_frequency CHECK (((frequency)::text = ANY (ARRAY[('daily'::character varying)::text, ('weekly'::character varying)::text, ('monthly'::character varying)::text, ('quarterly'::character varying)::text, ('half_yearly'::character varying)::text, ('yearly'::character varying)::text]))),
    CONSTRAINT pay_bonuses_plan_type CHECK (((plan_type)::text = ANY (ARRAY[('trip_target'::character varying)::text, ('reliability_otp'::character varying)::text, ('reliability_attendance'::character varying)::text])))
);


--
-- Name: pay_bonuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_bonuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_bonuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_bonuses_id_seq OWNED BY public.pay_bonuses.id;


--
-- Name: pay_rate_period_ranges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_rate_period_ranges (
    id bigint NOT NULL,
    pay_rate_period_id bigint NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_rate_period_ranges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_rate_period_ranges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_rate_period_ranges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_rate_period_ranges_id_seq OWNED BY public.pay_rate_period_ranges.id;


--
-- Name: pay_rate_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_rate_periods (
    id bigint NOT NULL,
    pay_rate_plan_id bigint NOT NULL,
    name character varying NOT NULL,
    days character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    takes_priority boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_rate_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_rate_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_rate_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_rate_periods_id_seq OWNED BY public.pay_rate_periods.id;


--
-- Name: pay_rate_plan_vehicle_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_rate_plan_vehicle_types (
    id bigint NOT NULL,
    pay_rate_plan_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_rate_plan_vehicle_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_rate_plan_vehicle_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_rate_plan_vehicle_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_rate_plan_vehicle_types_id_seq OWNED BY public.pay_rate_plan_vehicle_types.id;


--
-- Name: pay_rate_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_rate_plans (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    locked_at timestamp(6) without time zone,
    locked_by_id bigint,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_rate_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_rate_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_rate_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_rate_plans_id_seq OWNED BY public.pay_rate_plans.id;


--
-- Name: pay_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_rates (
    id bigint NOT NULL,
    pay_rate_period_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    per_trip numeric(12,2),
    per_hour numeric(12,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_rates_id_seq OWNED BY public.pay_rates.id;


--
-- Name: pay_rewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_rewards (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    title character varying NOT NULL,
    description text,
    photo character varying,
    points_required integer NOT NULL,
    status character varying DEFAULT 'inactive'::character varying NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT pay_rewards_status CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('inactive'::character varying)::text])))
);


--
-- Name: pay_rewards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_rewards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_rewards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_rewards_id_seq OWNED BY public.pay_rewards.id;


--
-- Name: pay_scheme_route_bands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_scheme_route_bands (
    id bigint NOT NULL,
    pay_scheme_id bigint NOT NULL,
    up_to_minutes integer,
    monthly_amount numeric(12,2) NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_scheme_route_bands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_scheme_route_bands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_scheme_route_bands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_scheme_route_bands_id_seq OWNED BY public.pay_scheme_route_bands.id;


--
-- Name: pay_scheme_target_tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_scheme_target_tiers (
    id bigint NOT NULL,
    pay_scheme_id bigint NOT NULL,
    period character varying NOT NULL,
    target_trips integer NOT NULL,
    pay_as character varying DEFAULT 'lump_sum'::character varying NOT NULL,
    amount numeric(12,2) DEFAULT 0.0 NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT pay_scheme_target_tiers_period CHECK (((period)::text = ANY (ARRAY[('weekly'::character varying)::text, ('monthly'::character varying)::text])))
);


--
-- Name: pay_scheme_target_tiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_scheme_target_tiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_scheme_target_tiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_scheme_target_tiers_id_seq OWNED BY public.pay_scheme_target_tiers.id;


--
-- Name: pay_scheme_volume_tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_scheme_volume_tiers (
    id bigint NOT NULL,
    pay_scheme_id bigint NOT NULL,
    from_trip integer NOT NULL,
    to_trip integer,
    boost_type character varying DEFAULT 'flat'::character varying NOT NULL,
    boost_value numeric(12,2) DEFAULT 0.0 NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_scheme_volume_tiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_scheme_volume_tiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_scheme_volume_tiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_scheme_volume_tiers_id_seq OWNED BY public.pay_scheme_volume_tiers.id;


--
-- Name: pay_schemes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_schemes (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    is_default boolean DEFAULT false NOT NULL,
    scheme_type character varying DEFAULT 'basic_plus_trips'::character varying NOT NULL,
    pay_rate_plan_id bigint,
    basic_salary numeric(12,2) DEFAULT 0.0 NOT NULL,
    basic_covers_daily_trips boolean DEFAULT false NOT NULL,
    basic_covered_daily_trips integer DEFAULT 1 NOT NULL,
    basic_covered_schedule character varying DEFAULT 'mon-fri'::character varying NOT NULL,
    basic_cover_ph boolean DEFAULT false NOT NULL,
    disposal_counts_as_trips boolean DEFAULT false NOT NULL,
    has_guarantee boolean DEFAULT false NOT NULL,
    guaranteed_amount numeric(12,2) DEFAULT 2200.0 NOT NULL,
    on_top_ph boolean DEFAULT false NOT NULL,
    on_top_sat boolean DEFAULT false NOT NULL,
    on_top_sun boolean DEFAULT false NOT NULL,
    has_post_guarantee_boost boolean DEFAULT false NOT NULL,
    post_guarantee_boost_type character varying DEFAULT 'percentage'::character varying NOT NULL,
    post_guarantee_boost_value numeric(12,2) DEFAULT 50.0 NOT NULL,
    has_rejection_penalty boolean DEFAULT false NOT NULL,
    rejection_allowed_jobs integer DEFAULT 0 NOT NULL,
    rejection_fallback_basic numeric(12,2) DEFAULT 0.0 NOT NULL,
    rejection_keeps_incentives boolean DEFAULT true NOT NULL,
    monthly_pay_amount numeric(12,2) DEFAULT 2200.0 NOT NULL,
    monthly_minimum_type character varying DEFAULT 'daily'::character varying NOT NULL,
    monthly_daily_trips integer DEFAULT 6 NOT NULL,
    monthly_trips integer DEFAULT 150 NOT NULL,
    monthly_schedule character varying DEFAULT 'mon-fri'::character varying NOT NULL,
    monthly_cover_ph boolean DEFAULT false NOT NULL,
    shift_salary numeric(12,2) DEFAULT 0.0 NOT NULL,
    shift_start_time integer DEFAULT 480 NOT NULL,
    shift_end_time integer DEFAULT 1080 NOT NULL,
    shift_working_days character varying[] DEFAULT '{mon,tue,wed,thu,fri}'::character varying[] NOT NULL,
    shift_overtime_pay_type character varying DEFAULT 'trip_rates'::character varying NOT NULL,
    shift_overtime_hourly_rate numeric(12,2) DEFAULT 0.0 NOT NULL,
    school_routes_pay boolean DEFAULT false NOT NULL,
    school_routes_count boolean DEFAULT false NOT NULL,
    school_routes_in_guarantee boolean DEFAULT true NOT NULL,
    has_daily_volume_incentive boolean DEFAULT false NOT NULL,
    daily_volume_in_guarantee boolean DEFAULT false NOT NULL,
    has_weekly_target_incentive boolean DEFAULT false NOT NULL,
    weekly_target_in_guarantee boolean DEFAULT false NOT NULL,
    has_monthly_target_incentive boolean DEFAULT false NOT NULL,
    monthly_target_in_guarantee boolean DEFAULT false NOT NULL,
    locked_at timestamp(6) without time zone,
    locked_by_id bigint,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT pay_schemes_type CHECK (((scheme_type)::text = ANY (ARRAY[('basic_plus_trips'::character varying)::text, ('monthly_with_minimum'::character varying)::text, ('shift_based'::character varying)::text])))
);


--
-- Name: pay_schemes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_schemes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_schemes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_schemes_id_seq OWNED BY public.pay_schemes.id;


--
-- Name: pay_simulator_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_simulator_templates (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    slot integer NOT NULL,
    name character varying NOT NULL,
    description text,
    month date NOT NULL,
    pay_scheme_id bigint,
    vehicle_type_id bigint,
    rejected integer DEFAULT 0 NOT NULL,
    on_time_percent integer,
    attendance_percent integer,
    school_holidays_from date,
    school_holidays_to date,
    routes jsonb DEFAULT '[]'::jsonb NOT NULL,
    jobs jsonb DEFAULT '{}'::jsonb NOT NULL,
    saved_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT pay_simulator_templates_slot CHECK (((slot >= 1) AND (slot <= 5)))
);


--
-- Name: pay_simulator_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_simulator_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_simulator_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_simulator_templates_id_seq OWNED BY public.pay_simulator_templates.id;


--
-- Name: pickup_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pickup_points (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    postal_codes character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    lat numeric(10,7),
    lng numeric(10,7),
    note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pickup_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pickup_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pickup_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pickup_points_id_seq OWNED BY public.pickup_points.id;


--
-- Name: plan_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plan_comments (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_plan_id bigint NOT NULL,
    user_id bigint,
    body text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: plan_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plan_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plan_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plan_comments_id_seq OWNED BY public.plan_comments.id;


--
-- Name: policy_reminders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.policy_reminders (
    id bigint NOT NULL,
    school_policy_version_id bigint NOT NULL,
    "position" integer NOT NULL,
    timing character varying NOT NULL,
    days integer DEFAULT 0 NOT NULL,
    email boolean DEFAULT false NOT NULL,
    whatsapp boolean DEFAULT false NOT NULL,
    app boolean DEFAULT false NOT NULL,
    email_subject character varying,
    email_body text,
    whatsapp_body text,
    app_title character varying,
    app_body character varying
);


--
-- Name: policy_reminders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.policy_reminders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: policy_reminders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.policy_reminders_id_seq OWNED BY public.policy_reminders.id;


--
-- Name: portal_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portal_accounts (
    id bigint NOT NULL,
    email character varying NOT NULL,
    name character varying,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    password_set_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: portal_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.portal_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: portal_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.portal_accounts_id_seq OWNED BY public.portal_accounts.id;


--
-- Name: portal_jwts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portal_jwts (
    id bigint NOT NULL,
    portal_account_id bigint NOT NULL,
    client_user_id bigint,
    jti character varying NOT NULL,
    aud character varying,
    exp timestamp(6) without time zone NOT NULL,
    name character varying,
    last_used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: portal_jwts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.portal_jwts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: portal_jwts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.portal_jwts_id_seq OWNED BY public.portal_jwts.id;


--
-- Name: portal_sign_in_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portal_sign_in_codes (
    id bigint NOT NULL,
    portal_account_id bigint NOT NULL,
    purpose character varying NOT NULL,
    code_digest character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    used_at timestamp(6) without time zone,
    ip character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT portal_sign_in_codes_purpose CHECK (((purpose)::text = ANY (ARRAY[('first'::character varying)::text, ('reset'::character varying)::text])))
);


--
-- Name: portal_sign_in_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.portal_sign_in_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: portal_sign_in_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.portal_sign_in_codes_id_seq OWNED BY public.portal_sign_in_codes.id;


--
-- Name: postal_geocodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.postal_geocodes (
    id bigint NOT NULL,
    country character varying DEFAULT 'SG'::character varying NOT NULL,
    postal character varying NOT NULL,
    found boolean NOT NULL,
    lat numeric(10,7),
    lng numeric(10,7),
    address character varying,
    looked_up_at timestamp with time zone NOT NULL
);


--
-- Name: postal_geocodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.postal_geocodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: postal_geocodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.postal_geocodes_id_seq OWNED BY public.postal_geocodes.id;


--
-- Name: public_holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.public_holidays (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    date date NOT NULL,
    name character varying NOT NULL,
    observed boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: public_holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.public_holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.public_holidays_id_seq OWNED BY public.public_holidays.id;


--
-- Name: rate_card_amounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_card_amounts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    rate_card_id bigint NOT NULL,
    kind character varying NOT NULL,
    rate_card_distance_band_id bigint,
    vehicle_type_id bigint NOT NULL,
    amount numeric(10,2) DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rate_card_amounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_card_amounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_card_amounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_card_amounts_id_seq OWNED BY public.rate_card_amounts.id;


--
-- Name: rate_card_distance_bands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_card_distance_bands (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    rate_card_id bigint NOT NULL,
    "position" integer NOT NULL,
    up_to_km numeric(8,1),
    per_km boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rate_card_distance_bands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_card_distance_bands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_card_distance_bands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_card_distance_bands_id_seq OWNED BY public.rate_card_distance_bands.id;


--
-- Name: rate_card_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_card_periods (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    rate_card_id bigint NOT NULL,
    name character varying NOT NULL,
    days character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    override boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rate_card_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_card_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_card_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_card_periods_id_seq OWNED BY public.rate_card_periods.id;


--
-- Name: rate_card_ranges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_card_ranges (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    rate_card_period_id bigint NOT NULL,
    starts_at integer NOT NULL,
    ends_at integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rate_card_ranges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_card_ranges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_card_ranges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_card_ranges_id_seq OWNED BY public.rate_card_ranges.id;


--
-- Name: rate_card_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_card_rates (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    rate_card_period_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    trip_rate numeric(10,2) DEFAULT 0.0 NOT NULL,
    hourly_rate numeric(10,2) DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rate_card_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_card_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_card_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_card_rates_id_seq OWNED BY public.rate_card_rates.id;


--
-- Name: rate_card_vehicle_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_card_vehicle_types (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    rate_card_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rate_card_vehicle_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_card_vehicle_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_card_vehicle_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_card_vehicle_types_id_seq OWNED BY public.rate_card_vehicle_types.id;


--
-- Name: rate_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_cards (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    default_card boolean DEFAULT false NOT NULL,
    wait_free_minutes integer DEFAULT 10 NOT NULL,
    wait_fee numeric(10,2) DEFAULT 15.0 NOT NULL,
    wait_block_minutes integer DEFAULT 15 NOT NULL,
    distance_pricing boolean DEFAULT false NOT NULL,
    stop_fees boolean DEFAULT false NOT NULL,
    disposal_mode character varying DEFAULT 'hourly'::character varying NOT NULL,
    disposal_free_km numeric(8,1) DEFAULT 0.0 NOT NULL,
    meet_and_greet boolean DEFAULT false NOT NULL,
    meet_and_greet_fee numeric(10,2) DEFAULT 0.0 NOT NULL,
    archived_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: rate_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_cards_id_seq OWNED BY public.rate_cards.id;


--
-- Name: registration_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.registration_messages (
    id bigint NOT NULL,
    school_registration_id bigint NOT NULL,
    key character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email boolean DEFAULT true NOT NULL,
    whatsapp boolean DEFAULT true NOT NULL,
    app boolean DEFAULT true NOT NULL,
    offset_days integer,
    offset_hours integer,
    subject character varying,
    body text,
    whatsapp_body text,
    scheduled boolean DEFAULT false NOT NULL,
    released_at timestamp with time zone
);


--
-- Name: registration_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.registration_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: registration_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.registration_messages_id_seq OWNED BY public.registration_messages.id;


--
-- Name: replacement_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.replacement_notifications (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    replacement_id bigint NOT NULL,
    audiences character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    channels character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    message text NOT NULL,
    sent_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: replacement_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.replacement_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: replacement_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.replacement_notifications_id_seq OWNED BY public.replacement_notifications.id;


--
-- Name: replacements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.replacements (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    kind character varying NOT NULL,
    scope character varying DEFAULT 'run'::character varying NOT NULL,
    trip_id bigint,
    run_date date,
    trip_run_id bigint,
    slot_no integer,
    original_vehicle_id bigint NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    driver_name character varying,
    driver_phone character varying,
    handover_stop character varying,
    handover_time integer,
    eta character varying,
    pay_split character varying,
    original_share integer,
    arranged_by character varying DEFAULT 'operator'::character varying NOT NULL,
    deduction numeric(12,2),
    premium numeric(12,2),
    reason text,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    school_route_id bigint,
    CONSTRAINT replacements_dates CHECK ((ends_on >= starts_on)),
    CONSTRAINT replacements_kind CHECK (((kind)::text = ANY (ARRAY[('drv'::character varying)::text, ('veh'::character varying)::text, ('crew'::character varying)::text, ('hand'::character varying)::text]))),
    CONSTRAINT replacements_range_kinds CHECK ((((scope)::text = 'run'::text) OR ((kind)::text = ANY (ARRAY[('drv'::character varying)::text, ('veh'::character varying)::text])))),
    CONSTRAINT replacements_run_source CHECK ((((scope)::text = 'range'::text) OR (num_nonnulls(trip_id, school_route_id) = 1)))
);


--
-- Name: replacements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.replacements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: replacements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.replacements_id_seq OWNED BY public.replacements.id;


--
-- Name: rider_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rider_assignments (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    rid character varying NOT NULL,
    stop_point_id bigint NOT NULL,
    school_plan_id bigint,
    manual boolean DEFAULT false NOT NULL,
    notified_at timestamp with time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rider_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rider_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rider_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rider_assignments_id_seq OWNED BY public.rider_assignments.id;


--
-- Name: rider_datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rider_datasets (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    effective_from date NOT NULL,
    file character varying,
    file_name character varying NOT NULL,
    riders_count integer DEFAULT 0 NOT NULL,
    unlocated_count integer DEFAULT 0 NOT NULL,
    status character varying DEFAULT 'locating'::character varying NOT NULL,
    uploaded_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rider_datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rider_datasets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rider_datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rider_datasets_id_seq OWNED BY public.rider_datasets.id;


--
-- Name: rider_point_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rider_point_links (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    stop_point_id bigint NOT NULL,
    kind character varying NOT NULL,
    rid character varying,
    postal character varying,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT rider_point_links_one_target CHECK ((num_nonnulls(rid, postal) = 1))
);


--
-- Name: rider_point_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rider_point_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rider_point_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rider_point_links_id_seq OWNED BY public.rider_point_links.id;


--
-- Name: route_charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_charges (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    school_route_id bigint,
    starts_on date NOT NULL,
    kind character varying DEFAULT 'amt'::character varying NOT NULL,
    value numeric(12,2) NOT NULL,
    reason character varying NOT NULL,
    note character varying,
    status character varying DEFAULT 'ok'::character varying NOT NULL,
    carried_from_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: route_charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.route_charges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: route_charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.route_charges_id_seq OWNED BY public.route_charges.id;


--
-- Name: route_list_version_stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_list_version_stops (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    route_list_version_id bigint NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    scheduled_time integer,
    address text,
    driver_note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: route_list_version_stops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.route_list_version_stops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: route_list_version_stops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.route_list_version_stops_id_seq OWNED BY public.route_list_version_stops.id;


--
-- Name: route_list_version_students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_list_version_students (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    route_list_version_stop_id bigint NOT NULL,
    key uuid NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    name character varying NOT NULL,
    class_name character varying,
    parent_name character varying,
    phone character varying,
    phone2 character varying,
    note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: route_list_version_students_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.route_list_version_students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: route_list_version_students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.route_list_version_students_id_seq OWNED BY public.route_list_version_students.id;


--
-- Name: route_list_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_list_versions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    name character varying NOT NULL,
    valid_until date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: route_list_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.route_list_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: route_list_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.route_list_versions_id_seq OWNED BY public.route_list_versions.id;


--
-- Name: routing_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.routing_runs (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    session character varying NOT NULL,
    plan_date date NOT NULL,
    status character varying DEFAULT 'queued'::character varying NOT NULL,
    params jsonb DEFAULT '{}'::jsonb NOT NULL,
    input jsonb DEFAULT '{}'::jsonb NOT NULL,
    result jsonb,
    error text,
    no_stop_rids character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    conflict_rids character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    ms integer,
    created_by_id bigint,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    kind character varying DEFAULT 'new'::character varying NOT NULL,
    target_plan_id bigint
);


--
-- Name: routing_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.routing_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: routing_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.routing_runs_id_seq OWNED BY public.routing_runs.id;


--
-- Name: routing_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.routing_settings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    params jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: routing_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.routing_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: routing_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.routing_settings_id_seq OWNED BY public.routing_settings.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: school_attendant_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_attendant_policies (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    needs character varying DEFAULT 'statutory'::character varying NOT NULL,
    sizes character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    provided_by character varying DEFAULT 'operator'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_attendant_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_attendant_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_attendant_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_attendant_policies_id_seq OWNED BY public.school_attendant_policies.id;


--
-- Name: school_bill_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_bill_lines (
    id bigint NOT NULL,
    school_bill_id bigint NOT NULL,
    child_name character varying,
    description character varying NOT NULL,
    amount numeric(12,2) NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: school_bill_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_bill_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_bill_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_bill_lines_id_seq OWNED BY public.school_bill_lines.id;


--
-- Name: school_bills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_bills (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    academic_year_id bigint,
    family_id bigint,
    school_rider_id bigint,
    bus_request_id bigint,
    number character varying NOT NULL,
    kind character varying DEFAULT 'first'::character varying NOT NULL,
    status character varying DEFAULT 'open'::character varying NOT NULL,
    bill_to character varying,
    period_label character varying,
    period_starts_on date,
    issued_on date NOT NULL,
    due_at timestamp with time zone,
    subtotal numeric(12,2) NOT NULL,
    gst_rate numeric(5,2) DEFAULT 0.0 NOT NULL,
    gst_amount numeric(12,2) DEFAULT 0.0 NOT NULL,
    total numeric(12,2) NOT NULL,
    paid_at timestamp with time zone,
    method character varying,
    recorded_by_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    gross numeric(12,2),
    credit_used numeric(12,2) DEFAULT 0.0 NOT NULL,
    week_of date
);


--
-- Name: school_bills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_bills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_bills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_bills_id_seq OWNED BY public.school_bills.id;


--
-- Name: school_bus_size_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_bus_size_rates (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    bus_type character varying NOT NULL,
    fixed_on boolean DEFAULT true NOT NULL,
    monthly numeric(12,2),
    rider_on boolean DEFAULT false NOT NULL,
    base_price numeric(12,2),
    riders_included integer,
    per_rider numeric(12,2),
    default_mode character varying DEFAULT 'fixed'::character varying NOT NULL,
    ba_operator numeric(12,2),
    ba_us numeric(12,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_bus_size_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_bus_size_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_bus_size_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_bus_size_rates_id_seq OWNED BY public.school_bus_size_rates.id;


--
-- Name: school_holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_holidays (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    name character varying NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    public_holiday_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_holidays_id_seq OWNED BY public.school_holidays.id;


--
-- Name: school_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_levels (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    section character varying DEFAULT 'custom'::character varying NOT NULL,
    final boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_levels_id_seq OWNED BY public.school_levels.id;


--
-- Name: school_operator_pays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_operator_pays (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    scheme character varying DEFAULT 'all'::character varying NOT NULL,
    paid_months integer[] DEFAULT '{1,2,3,4,5,6,7,8,9,10,11,12}'::integer[] NOT NULL,
    part_pct numeric(5,2) DEFAULT 50.0 NOT NULL,
    part_basis character varying DEFAULT 'school'::character varying NOT NULL,
    break_months integer[] DEFAULT '{6,12}'::integer[] NOT NULL,
    break_pay character varying DEFAULT 'full'::character varying NOT NULL,
    earn_by character varying DEFAULT 'terms'::character varying NOT NULL,
    grace_start_days integer DEFAULT 0 NOT NULL,
    deduct_days integer DEFAULT 0 NOT NULL,
    updated_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_operator_pays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_operator_pays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_operator_pays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_operator_pays_id_seq OWNED BY public.school_operator_pays.id;


--
-- Name: school_payment_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_payment_methods (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    bank_on boolean DEFAULT true NOT NULL,
    bank_fee_kind character varying DEFAULT 'none'::character varying NOT NULL,
    bank_fee numeric(12,2),
    paynow_on boolean DEFAULT true NOT NULL,
    paynow_fee_kind character varying DEFAULT 'none'::character varying NOT NULL,
    paynow_fee numeric(12,2),
    card_on boolean DEFAULT false NOT NULL,
    card_fee_kind character varying DEFAULT 'none'::character varying NOT NULL,
    card_fee numeric(12,2),
    own_account boolean DEFAULT false NOT NULL,
    bank_id bigint,
    account_number character varying,
    account_name character varying,
    paynow_id character varying,
    updated_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_payment_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_payment_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_payment_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_payment_methods_id_seq OWNED BY public.school_payment_methods.id;


--
-- Name: school_plan_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_plan_changes (
    id bigint NOT NULL,
    school_plan_id bigint NOT NULL,
    bus_request_id bigint,
    from_date date NOT NULL,
    rid character varying NOT NULL,
    op character varying NOT NULL,
    text character varying NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: school_plan_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_plan_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_plan_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_plan_changes_id_seq OWNED BY public.school_plan_changes.id;


--
-- Name: school_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_plans (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    name character varying NOT NULL,
    session character varying NOT NULL,
    days integer[] DEFAULT '{1,2,3,4,5}'::integer[] NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    in_use boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    source character varying DEFAULT 'manual'::character varying NOT NULL,
    priority character varying,
    params jsonb,
    summary jsonb,
    unassigned jsonb DEFAULT '[]'::jsonb NOT NULL,
    stale boolean DEFAULT false NOT NULL,
    adopted_at timestamp with time zone,
    routing_run_id bigint,
    adopted_by_id bigint,
    created_by_id bigint
);


--
-- Name: school_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_plans_id_seq OWNED BY public.school_plans.id;


--
-- Name: school_policy_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_policy_versions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    version integer NOT NULL,
    effective_on date NOT NULL,
    due_rule character varying DEFAULT 'before'::character varying NOT NULL,
    due_days_before integer DEFAULT 14 NOT NULL,
    due_day integer DEFAULT 1 NOT NULL,
    late_type character varying DEFAULT 'flat'::character varying NOT NULL,
    late_flat numeric(12,2),
    late_pct numeric(5,2),
    late_cap numeric(12,2),
    late_grace_days integer DEFAULT 7 NOT NULL,
    late_flag_days integer DEFAULT 30 NOT NULL,
    withdrawal_notice integer DEFAULT 1 NOT NULL,
    withdrawal_unit character varying DEFAULT 'months'::character varying NOT NULL,
    refund_basis character varying DEFAULT 'days'::character varying NOT NULL,
    refund_method character varying DEFAULT 'credit'::character varying NOT NULL,
    refund_within_days integer DEFAULT 30 NOT NULL,
    withdrawal_fee numeric(12,2),
    address_notice_days integer DEFAULT 14 NOT NULL,
    address_start character varying DEFAULT 'any'::character varying NOT NULL,
    address_max_days integer DEFAULT 90 NOT NULL,
    deposit_amount numeric(12,2) DEFAULT 0.0 NOT NULL,
    deposit_return character varying DEFAULT 'offset'::character varying NOT NULL,
    registration_fee numeric(12,2) DEFAULT 0.0 NOT NULL,
    ack_required boolean DEFAULT true NOT NULL,
    ack_reaccept boolean DEFAULT true NOT NULL,
    ack_text text,
    published_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_policy_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_policy_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_policy_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_policy_versions_id_seq OWNED BY public.school_policy_versions.id;


--
-- Name: school_registrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_registrations (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    renew_from date NOT NULL,
    renew_to date NOT NULL,
    general_from date NOT NULL,
    general_to date NOT NULL,
    service_starts_on date NOT NULL,
    confirm_hours integer DEFAULT 48 NOT NULL,
    ack_days integer DEFAULT 3 NOT NULL,
    plan_weeks integer DEFAULT 3 NOT NULL,
    levels character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    sessions character varying[] DEFAULT '{AM,PM,CCA}'::character varying[] NOT NULL,
    grad_on boolean DEFAULT true NOT NULL,
    grad_message text,
    grad_link boolean DEFAULT true NOT NULL,
    auto_renew boolean DEFAULT true NOT NULL,
    renew_check_address boolean DEFAULT true NOT NULL,
    renew_check_session boolean DEFAULT true NOT NULL,
    renew_check_debt boolean DEFAULT true NOT NULL,
    auto_near boolean DEFAULT false NOT NULL,
    near_km numeric(5,2) DEFAULT 3.0 NOT NULL,
    near_needs_cover boolean DEFAULT true NOT NULL,
    auto_siblings boolean DEFAULT false NOT NULL,
    siblings_need_cover boolean DEFAULT true NOT NULL,
    run_mode character varying DEFAULT 'arrive'::character varying NOT NULL,
    run_at integer DEFAULT 540 NOT NULL,
    seats_buffer integer DEFAULT 3 NOT NULL,
    waitlist_auto boolean DEFAULT false NOT NULL,
    show_fare boolean DEFAULT true NOT NULL,
    extra_terms text,
    asks character varying[] DEFAULT '{cls,med,emerg,cca}'::character varying[] NOT NULL,
    saved_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_registrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_registrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_registrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_registrations_id_seq OWNED BY public.school_registrations.id;


--
-- Name: school_riders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_riders (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    rider_dataset_id bigint,
    rid character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    name_order character varying DEFAULT 'last'::character varying NOT NULL,
    name character varying NOT NULL,
    gender character varying,
    grade character varying,
    address character varying,
    postal character varying NOT NULL,
    lat numeric(10,7),
    lng numeric(10,7),
    am boolean DEFAULT true NOT NULL,
    pm boolean DEFAULT true NOT NULL,
    cca_days integer[] DEFAULT '{}'::integer[] NOT NULL,
    starts_on date,
    ends_on date,
    parent_name character varying,
    parent_contact character varying,
    remarks text,
    source character varying DEFAULT 'csv'::character varying NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_riders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_riders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_riders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_riders_id_seq OWNED BY public.school_riders.id;


--
-- Name: school_route_labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_route_labels (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    session character varying NOT NULL,
    prefix character varying DEFAULT ''::character varying NOT NULL,
    start integer DEFAULT 1 NOT NULL,
    digits integer DEFAULT 0 NOT NULL,
    suffix character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_route_labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_route_labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_route_labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_route_labels_id_seq OWNED BY public.school_route_labels.id;


--
-- Name: school_route_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_route_prices (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_route_id bigint NOT NULL,
    effective_from date NOT NULL,
    mode character varying DEFAULT 'fixed'::character varying NOT NULL,
    monthly numeric(12,2),
    base_price numeric(12,2),
    riders_included integer,
    per_rider numeric(12,2),
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_route_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_route_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_route_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_route_prices_id_seq OWNED BY public.school_route_prices.id;


--
-- Name: school_route_replacements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_route_replacements (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_route_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    arranged_by character varying DEFAULT 'operator'::character varying NOT NULL,
    daily_rate numeric(12,2),
    deduct_from_operator boolean DEFAULT true NOT NULL,
    reason text,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_route_replacements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_route_replacements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_route_replacements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_route_replacements_id_seq OWNED BY public.school_route_replacements.id;


--
-- Name: school_route_riders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_route_riders (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_route_id bigint NOT NULL,
    school_route_stop_id bigint NOT NULL,
    rid character varying NOT NULL
);


--
-- Name: school_route_riders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_route_riders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_route_riders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_route_riders_id_seq OWNED BY public.school_route_riders.id;


--
-- Name: school_route_stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_route_stops (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_route_id bigint NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    lat numeric(10,7),
    lng numeric(10,7),
    scheduled_time integer,
    riders_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    dwell_seconds integer,
    stop_id bigint,
    stop_point_id bigint
);


--
-- Name: school_route_stops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_route_stops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_route_stops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_route_stops_id_seq OWNED BY public.school_route_stops.id;


--
-- Name: school_route_vehicle_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_route_vehicle_changes (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_route_id bigint NOT NULL,
    vehicle_id bigint,
    effective_from date NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_route_vehicle_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_route_vehicle_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_route_vehicle_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_route_vehicle_changes_id_seq OWNED BY public.school_route_vehicle_changes.id;


--
-- Name: school_routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_routes (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_plan_id bigint NOT NULL,
    number integer NOT NULL,
    label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    riders_count integer DEFAULT 0 NOT NULL,
    attendant_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    route_key character varying,
    bus_type character varying,
    seats integer,
    student_seats integer,
    capacity integer,
    floor integer,
    fill numeric(5,4),
    span_seconds integer,
    ride_minutes integer,
    badges character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    edited boolean DEFAULT false NOT NULL,
    manual boolean DEFAULT false NOT NULL,
    vias jsonb DEFAULT '[]'::jsonb NOT NULL,
    engine_route jsonb
);


--
-- Name: school_routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_routes_id_seq OWNED BY public.school_routes.id;


--
-- Name: school_special_days; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_special_days (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    date date NOT NULL,
    kind character varying NOT NULL,
    "time" integer,
    description character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_special_days_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_special_days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_special_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_special_days_id_seq OWNED BY public.school_special_days.id;


--
-- Name: school_stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_stops (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    postal_codes character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    areas jsonb DEFAULT '[]'::jsonb NOT NULL,
    off_point_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_stops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_stops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_stops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_stops_id_seq OWNED BY public.school_stops.id;


--
-- Name: schools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schools (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    client_id bigint,
    calendar_id bigint,
    name character varying NOT NULL,
    short_name character varying,
    address text,
    lat numeric(10,7),
    lng numeric(10,7),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    postal character varying,
    stops_changed_at timestamp with time zone
);


--
-- Name: schools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schools_id_seq OWNED BY public.schools.id;


--
-- Name: setup_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.setup_locks (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    school_id bigint NOT NULL,
    academic_year_id bigint,
    section character varying NOT NULL,
    locked_at timestamp with time zone NOT NULL,
    locked_by_id bigint
);


--
-- Name: setup_locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.setup_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: setup_locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.setup_locks_id_seq OWNED BY public.setup_locks.id;


--
-- Name: stop_photo_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stop_photo_requests (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    stop_point_id bigint NOT NULL,
    audience character varying DEFAULT 'parents'::character varying NOT NULL,
    school_rider_id bigint,
    max_submissions integer DEFAULT 6 NOT NULL,
    status character varying DEFAULT 'open'::character varying NOT NULL,
    auto boolean DEFAULT false NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: stop_photo_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stop_photo_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stop_photo_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stop_photo_requests_id_seq OWNED BY public.stop_photo_requests.id;


--
-- Name: stop_photo_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stop_photo_submissions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    stop_photo_request_id bigint NOT NULL,
    submitted_by_name character varying NOT NULL,
    role character varying NOT NULL,
    photo character varying NOT NULL,
    street_view_url character varying,
    annotations jsonb,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    submitted_at timestamp with time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: stop_photo_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stop_photo_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stop_photo_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stop_photo_submissions_id_seq OWNED BY public.stop_photo_submissions.id;


--
-- Name: stop_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stop_points (
    id bigint NOT NULL,
    stop_id bigint NOT NULL,
    suffix character varying NOT NULL,
    description character varying,
    usage character varying DEFAULT 'both'::character varying NOT NULL,
    sizes character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "primary" boolean DEFAULT false NOT NULL,
    lat numeric(10,7) NOT NULL,
    lng numeric(10,7) NOT NULL,
    subzone_code character varying,
    street_view_url character varying,
    photo character varying,
    photo_original character varying,
    photo_annotations jsonb,
    photo_credit character varying,
    retired_at timestamp with time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: stop_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stop_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stop_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stop_points_id_seq OWNED BY public.stop_points.id;


--
-- Name: stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stops (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    code character varying NOT NULL,
    subzone_code character varying NOT NULL,
    name character varying NOT NULL,
    library_status character varying DEFAULT 'approved'::character varying NOT NULL,
    owner_school_id bigint,
    requested_by_id bigint,
    requested_at timestamp with time zone,
    former_codes character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    created_by_id bigint,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: stops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stops_id_seq OWNED BY public.stops.id;


--
-- Name: student_attendances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_attendances (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    run_date date NOT NULL,
    trip_run_id bigint,
    slot_no integer DEFAULT 1 NOT NULL,
    student_key uuid NOT NULL,
    student_name character varying NOT NULL,
    boarded_at timestamp(6) without time zone,
    alighted_at timestamp(6) without time zone,
    absent boolean DEFAULT false NOT NULL,
    recorded_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: student_attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.student_attendances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: student_attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.student_attendances_id_seq OWNED BY public.student_attendances.id;


--
-- Name: tracking_devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracking_devices (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint,
    kind character varying NOT NULL,
    name character varying NOT NULL,
    identifier character varying,
    report_interval_seconds integer DEFAULT 10 NOT NULL,
    sharing_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tracking_devices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracking_devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracking_devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracking_devices_id_seq OWNED BY public.tracking_devices.id;


--
-- Name: tracking_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracking_links (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    token character varying NOT NULL,
    trip_id bigint NOT NULL,
    run_date date NOT NULL,
    trip_run_id bigint,
    slot_no integer DEFAULT 1 NOT NULL,
    snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tracking_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracking_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracking_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracking_links_id_seq OWNED BY public.tracking_links.id;


--
-- Name: trip_assignment_slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_assignment_slots (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_assignment_id bigint NOT NULL,
    trip_run_id bigint,
    slot_no integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_assignment_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_assignment_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_assignment_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_assignment_slots_id_seq OWNED BY public.trip_assignment_slots.id;


--
-- Name: trip_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_assignments (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    effective_from date NOT NULL,
    assignee character varying NOT NULL,
    operator_id bigint,
    vehicle_id bigint,
    pay_amount numeric(12,2),
    pay_basis character varying DEFAULT 'run'::character varying NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_assignments_id_seq OWNED BY public.trip_assignments.id;


--
-- Name: trip_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_attachments (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    file character varying NOT NULL,
    uploaded_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_attachments_id_seq OWNED BY public.trip_attachments.id;


--
-- Name: trip_occurrences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_occurrences (
    id bigint NOT NULL,
    date date NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint,
    trip_run_id bigint,
    run_key character varying,
    slot_no integer DEFAULT 1 NOT NULL,
    part integer DEFAULT 1 NOT NULL,
    client_id bigint,
    kind character varying NOT NULL,
    trip_label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    shift_minutes integer DEFAULT 0 NOT NULL,
    pax integer DEFAULT 0 NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    operator_id bigint,
    original_vehicle_id bigint,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by_id bigint,
    ended_at timestamp with time zone,
    issue_reason text,
    issue_raised_at timestamp with time zone,
    issue_raised_by_id bigint,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    trip_value numeric(10,2) DEFAULT 0 NOT NULL,
    operator_cost numeric(12,2),
    overridden_fields character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    source_digest character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    trip_assignment_id bigint,
    replacement_id bigint,
    driver_name character varying,
    driver_phone character varying,
    school_route_id bigint,
    skip_reason character varying,
    cancelled_by_client boolean DEFAULT false NOT NULL,
    max_delay_minutes integer,
    started_at timestamp with time zone,
    CONSTRAINT trip_occurrences_one_source CHECK ((num_nonnulls(trip_id, school_route_id) = 1)),
    CONSTRAINT trip_occurrences_status CHECK (((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text, ('removed'::character varying)::text, ('skipped'::character varying)::text])))
)
PARTITION BY RANGE (date);


--
-- Name: trip_occurrences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.trip_occurrences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: trip_occurrences_y2026m09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_occurrences_y2026m09 (
    id bigint NOT NULL,
    date date NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint,
    trip_run_id bigint,
    run_key character varying,
    slot_no integer DEFAULT 1 NOT NULL,
    part integer DEFAULT 1 NOT NULL,
    client_id bigint,
    kind character varying NOT NULL,
    trip_label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    shift_minutes integer DEFAULT 0 NOT NULL,
    pax integer DEFAULT 0 NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    operator_id bigint,
    original_vehicle_id bigint,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by_id bigint,
    ended_at timestamp with time zone,
    issue_reason text,
    issue_raised_at timestamp with time zone,
    issue_raised_by_id bigint,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    trip_value numeric(10,2) DEFAULT 0 NOT NULL,
    operator_cost numeric(12,2),
    overridden_fields character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    source_digest character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    trip_assignment_id bigint,
    replacement_id bigint,
    driver_name character varying,
    driver_phone character varying,
    school_route_id bigint,
    skip_reason character varying,
    cancelled_by_client boolean DEFAULT false NOT NULL,
    max_delay_minutes integer,
    started_at timestamp with time zone,
    CONSTRAINT trip_occurrences_one_source CHECK ((num_nonnulls(trip_id, school_route_id) = 1)),
    CONSTRAINT trip_occurrences_status CHECK (((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text, ('removed'::character varying)::text, ('skipped'::character varying)::text])))
);


--
-- Name: trip_occurrences_y2026m10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_occurrences_y2026m10 (
    id bigint NOT NULL,
    date date NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint,
    trip_run_id bigint,
    run_key character varying,
    slot_no integer DEFAULT 1 NOT NULL,
    part integer DEFAULT 1 NOT NULL,
    client_id bigint,
    kind character varying NOT NULL,
    trip_label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    shift_minutes integer DEFAULT 0 NOT NULL,
    pax integer DEFAULT 0 NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    operator_id bigint,
    original_vehicle_id bigint,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by_id bigint,
    ended_at timestamp with time zone,
    issue_reason text,
    issue_raised_at timestamp with time zone,
    issue_raised_by_id bigint,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    trip_value numeric(10,2) DEFAULT 0 NOT NULL,
    operator_cost numeric(12,2),
    overridden_fields character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    source_digest character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    trip_assignment_id bigint,
    replacement_id bigint,
    driver_name character varying,
    driver_phone character varying,
    school_route_id bigint,
    skip_reason character varying,
    cancelled_by_client boolean DEFAULT false NOT NULL,
    max_delay_minutes integer,
    started_at timestamp with time zone,
    CONSTRAINT trip_occurrences_one_source CHECK ((num_nonnulls(trip_id, school_route_id) = 1)),
    CONSTRAINT trip_occurrences_status CHECK (((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text, ('removed'::character varying)::text, ('skipped'::character varying)::text])))
);


--
-- Name: trip_occurrences_y2026m11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_occurrences_y2026m11 (
    id bigint NOT NULL,
    date date NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint,
    trip_run_id bigint,
    run_key character varying,
    slot_no integer DEFAULT 1 NOT NULL,
    part integer DEFAULT 1 NOT NULL,
    client_id bigint,
    kind character varying NOT NULL,
    trip_label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    shift_minutes integer DEFAULT 0 NOT NULL,
    pax integer DEFAULT 0 NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    operator_id bigint,
    original_vehicle_id bigint,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by_id bigint,
    ended_at timestamp with time zone,
    issue_reason text,
    issue_raised_at timestamp with time zone,
    issue_raised_by_id bigint,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    trip_value numeric(10,2) DEFAULT 0 NOT NULL,
    operator_cost numeric(12,2),
    overridden_fields character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    source_digest character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    trip_assignment_id bigint,
    replacement_id bigint,
    driver_name character varying,
    driver_phone character varying,
    school_route_id bigint,
    skip_reason character varying,
    cancelled_by_client boolean DEFAULT false NOT NULL,
    max_delay_minutes integer,
    started_at timestamp with time zone,
    CONSTRAINT trip_occurrences_one_source CHECK ((num_nonnulls(trip_id, school_route_id) = 1)),
    CONSTRAINT trip_occurrences_status CHECK (((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text, ('removed'::character varying)::text, ('skipped'::character varying)::text])))
);


--
-- Name: trip_occurrences_y2026m12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_occurrences_y2026m12 (
    id bigint NOT NULL,
    date date NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint,
    trip_run_id bigint,
    run_key character varying,
    slot_no integer DEFAULT 1 NOT NULL,
    part integer DEFAULT 1 NOT NULL,
    client_id bigint,
    kind character varying NOT NULL,
    trip_label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    shift_minutes integer DEFAULT 0 NOT NULL,
    pax integer DEFAULT 0 NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    operator_id bigint,
    original_vehicle_id bigint,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by_id bigint,
    ended_at timestamp with time zone,
    issue_reason text,
    issue_raised_at timestamp with time zone,
    issue_raised_by_id bigint,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    trip_value numeric(10,2) DEFAULT 0 NOT NULL,
    operator_cost numeric(12,2),
    overridden_fields character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    source_digest character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    trip_assignment_id bigint,
    replacement_id bigint,
    driver_name character varying,
    driver_phone character varying,
    school_route_id bigint,
    skip_reason character varying,
    cancelled_by_client boolean DEFAULT false NOT NULL,
    max_delay_minutes integer,
    started_at timestamp with time zone,
    CONSTRAINT trip_occurrences_one_source CHECK ((num_nonnulls(trip_id, school_route_id) = 1)),
    CONSTRAINT trip_occurrences_status CHECK (((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text, ('removed'::character varying)::text, ('skipped'::character varying)::text])))
);


--
-- Name: trip_occurrences_y2027m01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_occurrences_y2027m01 (
    id bigint NOT NULL,
    date date NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint,
    trip_run_id bigint,
    run_key character varying,
    slot_no integer DEFAULT 1 NOT NULL,
    part integer DEFAULT 1 NOT NULL,
    client_id bigint,
    kind character varying NOT NULL,
    trip_label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    shift_minutes integer DEFAULT 0 NOT NULL,
    pax integer DEFAULT 0 NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    operator_id bigint,
    original_vehicle_id bigint,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by_id bigint,
    ended_at timestamp with time zone,
    issue_reason text,
    issue_raised_at timestamp with time zone,
    issue_raised_by_id bigint,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    trip_value numeric(10,2) DEFAULT 0 NOT NULL,
    operator_cost numeric(12,2),
    overridden_fields character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    source_digest character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    trip_assignment_id bigint,
    replacement_id bigint,
    driver_name character varying,
    driver_phone character varying,
    school_route_id bigint,
    skip_reason character varying,
    cancelled_by_client boolean DEFAULT false NOT NULL,
    max_delay_minutes integer,
    started_at timestamp with time zone,
    CONSTRAINT trip_occurrences_one_source CHECK ((num_nonnulls(trip_id, school_route_id) = 1)),
    CONSTRAINT trip_occurrences_status CHECK (((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text, ('removed'::character varying)::text, ('skipped'::character varying)::text])))
);


--
-- Name: trip_occurrences_y2027m02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_occurrences_y2027m02 (
    id bigint NOT NULL,
    date date NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint,
    trip_run_id bigint,
    run_key character varying,
    slot_no integer DEFAULT 1 NOT NULL,
    part integer DEFAULT 1 NOT NULL,
    client_id bigint,
    kind character varying NOT NULL,
    trip_label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    shift_minutes integer DEFAULT 0 NOT NULL,
    pax integer DEFAULT 0 NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    operator_id bigint,
    original_vehicle_id bigint,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by_id bigint,
    ended_at timestamp with time zone,
    issue_reason text,
    issue_raised_at timestamp with time zone,
    issue_raised_by_id bigint,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    trip_value numeric(10,2) DEFAULT 0 NOT NULL,
    operator_cost numeric(12,2),
    overridden_fields character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    source_digest character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    trip_assignment_id bigint,
    replacement_id bigint,
    driver_name character varying,
    driver_phone character varying,
    school_route_id bigint,
    skip_reason character varying,
    cancelled_by_client boolean DEFAULT false NOT NULL,
    max_delay_minutes integer,
    started_at timestamp with time zone,
    CONSTRAINT trip_occurrences_one_source CHECK ((num_nonnulls(trip_id, school_route_id) = 1)),
    CONSTRAINT trip_occurrences_status CHECK (((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text, ('removed'::character varying)::text, ('skipped'::character varying)::text])))
);


--
-- Name: trip_occurrences_y2027m03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_occurrences_y2027m03 (
    id bigint NOT NULL,
    date date NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint,
    trip_run_id bigint,
    run_key character varying,
    slot_no integer DEFAULT 1 NOT NULL,
    part integer DEFAULT 1 NOT NULL,
    client_id bigint,
    kind character varying NOT NULL,
    trip_label character varying NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    shift_minutes integer DEFAULT 0 NOT NULL,
    pax integer DEFAULT 0 NOT NULL,
    vehicle_id bigint,
    driver_id bigint,
    operator_driver_id bigint,
    operator_id bigint,
    original_vehicle_id bigint,
    status character varying DEFAULT 'scheduled'::character varying NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by_id bigint,
    ended_at timestamp with time zone,
    issue_reason text,
    issue_raised_at timestamp with time zone,
    issue_raised_by_id bigint,
    price numeric(12,2) DEFAULT 0 NOT NULL,
    trip_value numeric(10,2) DEFAULT 0 NOT NULL,
    operator_cost numeric(12,2),
    overridden_fields character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    source_digest character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    trip_assignment_id bigint,
    replacement_id bigint,
    driver_name character varying,
    driver_phone character varying,
    school_route_id bigint,
    skip_reason character varying,
    cancelled_by_client boolean DEFAULT false NOT NULL,
    max_delay_minutes integer,
    started_at timestamp with time zone,
    CONSTRAINT trip_occurrences_one_source CHECK ((num_nonnulls(trip_id, school_route_id) = 1)),
    CONSTRAINT trip_occurrences_status CHECK (((status)::text = ANY (ARRAY[('scheduled'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text, ('removed'::character varying)::text, ('skipped'::character varying)::text])))
);


--
-- Name: trip_price_cells; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_price_cells (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    direction integer,
    trip_run_id bigint,
    slot_no integer,
    amount numeric(12,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_price_cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_price_cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_price_cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_price_cells_id_seq OWNED BY public.trip_price_cells.id;


--
-- Name: trip_route_vias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_route_vias (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    direction integer DEFAULT 1 NOT NULL,
    from_position integer NOT NULL,
    "position" integer NOT NULL,
    lat numeric(10,7) NOT NULL,
    lng numeric(10,7) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_route_vias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_route_vias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_route_vias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_route_vias_id_seq OWNED BY public.trip_route_vias.id;


--
-- Name: trip_run_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_run_groups (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_run_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_run_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_run_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_run_groups_id_seq OWNED BY public.trip_run_groups.id;


--
-- Name: trip_run_slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_run_slots (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_run_id bigint NOT NULL,
    slot_no integer NOT NULL,
    vehicle_id bigint,
    unassigned boolean DEFAULT false NOT NULL,
    trip_run_group_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_run_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_run_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_run_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_run_slots_id_seq OWNED BY public.trip_run_slots.id;


--
-- Name: trip_run_times; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_run_times (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_run_id bigint NOT NULL,
    trip_stop_id bigint NOT NULL,
    "time" integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_run_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_run_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_run_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_run_times_id_seq OWNED BY public.trip_run_times.id;


--
-- Name: trip_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_runs (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    direction integer DEFAULT 1 NOT NULL,
    "position" integer NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    trip_value numeric(10,2),
    standby_needed boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_runs_id_seq OWNED BY public.trip_runs.id;


--
-- Name: trip_standby_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_standby_photos (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_standby_id bigint NOT NULL,
    photo character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_standby_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_standby_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_standby_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_standby_photos_id_seq OWNED BY public.trip_standby_photos.id;


--
-- Name: trip_standbys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_standbys (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    location character varying NOT NULL,
    minutes integer DEFAULT 10 NOT NULL,
    lat numeric(10,7),
    lng numeric(10,7),
    address text,
    note text,
    street_view_url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_standbys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_standbys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_standbys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_standbys_id_seq OWNED BY public.trip_standbys.id;


--
-- Name: trip_stop_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_stop_photos (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_stop_id bigint NOT NULL,
    photo character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_stop_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_stop_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_stop_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_stop_photos_id_seq OWNED BY public.trip_stop_photos.id;


--
-- Name: trip_stop_students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_stop_students (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_stop_id bigint NOT NULL,
    key uuid DEFAULT gen_random_uuid() NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    name character varying NOT NULL,
    class_name character varying,
    parent_name character varying,
    phone character varying,
    phone2 character varying,
    note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_stop_students_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_stop_students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_stop_students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_stop_students_id_seq OWNED BY public.trip_stop_students.id;


--
-- Name: trip_stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_stops (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    direction integer DEFAULT 1 NOT NULL,
    "position" integer NOT NULL,
    name character varying NOT NULL,
    use character varying DEFAULT 'both'::character varying NOT NULL,
    address text,
    lat numeric(10,7),
    lng numeric(10,7),
    driver_note text,
    street_view_url character varying,
    client_site_id bigint,
    scheduled_time integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    return_name character varying
);


--
-- Name: trip_stops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_stops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_stops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_stops_id_seq OWNED BY public.trip_stops.id;


--
-- Name: trip_time_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_time_changes (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    effective_from date NOT NULL,
    minutes integer NOT NULL,
    trip_run_id bigint,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_time_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_time_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_time_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_time_changes_id_seq OWNED BY public.trip_time_changes.id;


--
-- Name: trip_vehicle_requirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_vehicle_requirements (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    vehicle_type_id bigint NOT NULL,
    count integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_vehicle_requirements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_vehicle_requirements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_vehicle_requirements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_vehicle_requirements_id_seq OWNED BY public.trip_vehicle_requirements.id;


--
-- Name: trip_vehicle_slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_vehicle_slots (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    slot_no integer NOT NULL,
    vehicle_id bigint,
    price numeric(12,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trip_vehicle_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_vehicle_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_vehicle_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_vehicle_slots_id_seq OWNED BY public.trip_vehicle_slots.id;


--
-- Name: trips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trips (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    client_id bigint NOT NULL,
    client_site_id bigint,
    kind character varying NOT NULL,
    title character varying NOT NULL,
    label character varying,
    trip_no bigint NOT NULL,
    trip_no_from date NOT NULL,
    trip_no_count integer DEFAULT 1 NOT NULL,
    starts_on date NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    hours numeric(5,2),
    days integer[] DEFAULT '{}'::integer[] NOT NULL,
    end_mode character varying DEFAULT 'none'::character varying NOT NULL,
    ends_on date,
    occurrence_count integer,
    skip_public_holidays boolean DEFAULT true NOT NULL,
    calendar_id bigint,
    pax integer DEFAULT 0 NOT NULL,
    luggage_on boolean DEFAULT false NOT NULL,
    luggage_cabin integer DEFAULT 0 NOT NULL,
    luggage_medium integer DEFAULT 0 NOT NULL,
    luggage_large integer DEFAULT 0 NOT NULL,
    luggage_extra_large integer DEFAULT 0 NOT NULL,
    luggage_oversized integer DEFAULT 0 NOT NULL,
    vehicles_count integer DEFAULT 1 NOT NULL,
    requestor_name character varying,
    requestor_email character varying,
    requestor_phone character varying,
    guest_is_requestor boolean DEFAULT true NOT NULL,
    guest_name character varying,
    guest_phone character varying,
    notes text,
    business_unit character varying,
    project character varying,
    booking_ref character varying,
    airport_direction character varying,
    flight_number character varying,
    flight_time integer,
    terminal character varying,
    wait_minutes integer DEFAULT 0 NOT NULL,
    meet_and_greet boolean DEFAULT false NOT NULL,
    signboard_name character varying,
    meet_and_greet_fee numeric(12,2) DEFAULT 0.0 NOT NULL,
    price numeric(12,2) DEFAULT 0.0 NOT NULL,
    price_per character varying DEFAULT 'route'::character varying NOT NULL,
    price_set character varying DEFAULT 'same'::character varying NOT NULL,
    price_basis character varying DEFAULT 'trip'::character varying NOT NULL,
    hourly_rate boolean DEFAULT false NOT NULL,
    trip_value numeric(10,2) DEFAULT 1.0 NOT NULL,
    trip_value_mode character varying DEFAULT 'trips'::character varying NOT NULL,
    trip_value_rounding character varying DEFAULT 'up'::character varying NOT NULL,
    operator_cost numeric(12,2),
    operator_cancel_rule character varying DEFAULT 'done'::character varying NOT NULL,
    subcontracted boolean DEFAULT false NOT NULL,
    client_end_customer_id bigint,
    service_for character varying,
    contractor_contact_name character varying,
    contractor_contact_phone character varying,
    require_contractor_app boolean DEFAULT false NOT NULL,
    pair_id bigint,
    is_return boolean DEFAULT false NOT NULL,
    return_billing character varying,
    created_by_id bigint,
    lock_version integer DEFAULT 0 NOT NULL,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    shuttle_return boolean DEFAULT false NOT NULL,
    shuttle_separate_return boolean DEFAULT false NOT NULL,
    price_by character varying DEFAULT 'all'::character varying NOT NULL,
    trip_value_per character varying DEFAULT 'run'::character varying NOT NULL,
    trip_value_return numeric(10,2),
    route_tags character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    color character varying,
    approved_riders_only boolean DEFAULT false NOT NULL,
    seat_reservation boolean DEFAULT false NOT NULL,
    head_count boolean DEFAULT false NOT NULL,
    no_fixed_bus boolean DEFAULT false NOT NULL,
    session character varying,
    paid_months_mode character varying DEFAULT 'all'::character varying NOT NULL,
    unpaid_months integer[] DEFAULT '{}'::integer[] NOT NULL,
    unpaid_month_share integer DEFAULT 50 NOT NULL,
    charge_no_school_days boolean DEFAULT true NOT NULL,
    school_time_estimated boolean DEFAULT false NOT NULL,
    route_list_name character varying,
    route_list_imported_at timestamp(6) without time zone,
    students_purged_at timestamp(6) without time zone,
    booking_trip_id bigint,
    CONSTRAINT trips_end_mode CHECK (((end_mode)::text = ANY (ARRAY[('none'::character varying)::text, ('never'::character varying)::text, ('date'::character varying)::text, ('count'::character varying)::text]))),
    CONSTRAINT trips_kind CHECK (((kind)::text = ANY (ARRAY[('ad_hoc'::character varying)::text, ('corporate_shuttle'::character varying)::text, ('airport_transfer'::character varying)::text, ('disposal'::character varying)::text, ('school_run'::character varying)::text])))
);


--
-- Name: trips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trips_id_seq OWNED BY public.trips.id;


--
-- Name: ura_subzones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ura_subzones (
    id bigint NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    planning_area character varying NOT NULL,
    planning_area_code character varying NOT NULL,
    region character varying NOT NULL,
    rings jsonb NOT NULL,
    min_lat double precision NOT NULL,
    max_lat double precision NOT NULL,
    min_lng double precision NOT NULL,
    max_lng double precision NOT NULL
);


--
-- Name: ura_subzones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ura_subzones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ura_subzones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ura_subzones_id_seq OWNED BY public.ura_subzones.id;


--
-- Name: user_notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_notification_preferences (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint NOT NULL,
    new_booking boolean DEFAULT true NOT NULL,
    client_approved boolean DEFAULT true NOT NULL,
    client_declined boolean DEFAULT true NOT NULL,
    acknowledged boolean DEFAULT true NOT NULL,
    cancel_request boolean DEFAULT true NOT NULL,
    email boolean DEFAULT true NOT NULL,
    seen_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_notification_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_notification_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_notification_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_notification_preferences_id_seq OWNED BY public.user_notification_preferences.id;


--
-- Name: user_schools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_schools (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    school_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_schools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_schools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_schools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_schools_id_seq OWNED BY public.user_schools.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    company_id bigint,
    name character varying NOT NULL,
    mobile character varying,
    avatar character varying,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    owner boolean DEFAULT false NOT NULL,
    permissions character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    last_seen_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    all_schools boolean DEFAULT true NOT NULL,
    display_name character varying,
    created_by_id bigint
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vehicle_cost_spike_acks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_cost_spike_acks (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    category character varying NOT NULL,
    month date NOT NULL,
    checked_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: vehicle_cost_spike_acks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_cost_spike_acks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_cost_spike_acks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_cost_spike_acks_id_seq OWNED BY public.vehicle_cost_spike_acks.id;


--
-- Name: vehicle_driver_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_driver_schedules (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    driver_id bigint,
    starts_on date NOT NULL,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: vehicle_driver_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_driver_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_driver_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_driver_schedules_id_seq OWNED BY public.vehicle_driver_schedules.id;


--
-- Name: vehicle_finance_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_finance_entries (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    kind character varying NOT NULL,
    category character varying NOT NULL,
    entry_on date NOT NULL,
    amount numeric(12,2) NOT NULL,
    repeats_monthly boolean DEFAULT false NOT NULL,
    repeat_until date,
    note text,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT vehicle_finance_entries_kind CHECK (((kind)::text = ANY (ARRAY[('revenue'::character varying)::text, ('cost'::character varying)::text])))
);


--
-- Name: vehicle_finance_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_finance_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_finance_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_finance_entries_id_seq OWNED BY public.vehicle_finance_entries.id;


--
-- Name: vehicle_financials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_financials (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    funding character varying DEFAULT 'loan'::character varying NOT NULL,
    purchase_price numeric(12,2),
    down_payment numeric(12,2),
    bought_on date,
    lender character varying,
    account_number character varying,
    loan_amount numeric(12,2),
    rate numeric(6,3),
    tenure_months integer,
    term_charge numeric(12,2),
    first_instalment numeric(12,2),
    monthly_instalment numeric(12,2),
    last_instalment numeric(12,2),
    first_due_on date,
    schedule_file character varying,
    document_read_id bigint,
    updated_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT vehicle_financials_funding CHECK (((funding)::text = ANY (ARRAY[('loan'::character varying)::text, ('cash'::character varying)::text])))
);


--
-- Name: vehicle_financials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_financials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_financials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_financials_id_seq OWNED BY public.vehicle_financials.id;


--
-- Name: vehicle_insurance_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_insurance_documents (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_insurance_policy_id bigint NOT NULL,
    file character varying NOT NULL,
    kind character varying DEFAULT 'other'::character varying NOT NULL,
    plate_on_document character varying,
    plate_differs boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: vehicle_insurance_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_insurance_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_insurance_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_insurance_documents_id_seq OWNED BY public.vehicle_insurance_documents.id;


--
-- Name: vehicle_insurance_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_insurance_policies (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    current boolean DEFAULT true NOT NULL,
    insurer character varying,
    policy_number character varying,
    cover_type character varying,
    starts_on date,
    ends_on date,
    excess numeric(12,2),
    excess_third_party numeric(12,2),
    hire_purchase_company character varying,
    agent character varying,
    holder character varying,
    premium numeric(12,2),
    gst numeric(12,2),
    total numeric(12,2),
    debit_note_number character varying,
    debit_note_date date,
    paid_on date,
    renewed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: vehicle_insurance_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_insurance_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_insurance_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_insurance_policies_id_seq OWNED BY public.vehicle_insurance_policies.id;


--
-- Name: vehicle_live_positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_live_positions (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    tracking_device_id bigint,
    recorded_at timestamp with time zone NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    speed_kmh real,
    heading smallint,
    battery_pct smallint,
    gps_signal character varying,
    gsm_bars smallint,
    occurrence_id bigint,
    occurrence_date date
);


--
-- Name: vehicle_live_positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_live_positions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_live_positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_live_positions_id_seq OWNED BY public.vehicle_live_positions.id;


--
-- Name: vehicle_loan_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_loan_payments (
    id bigint NOT NULL,
    vehicle_financial_id bigint NOT NULL,
    instalment_no integer NOT NULL,
    paid_on date NOT NULL,
    recorded_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: vehicle_loan_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_loan_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_loan_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_loan_payments_id_seq OWNED BY public.vehicle_loan_payments.id;


--
-- Name: vehicle_log_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_log_cards (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    vehicle_id bigint NOT NULL,
    uploaded_by_id bigint,
    file character varying NOT NULL,
    current boolean DEFAULT true NOT NULL,
    plate_on_card character varying,
    plate_conflict boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: vehicle_log_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_log_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_log_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_log_cards_id_seq OWNED BY public.vehicle_log_cards.id;


--
-- Name: vehicle_teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_teams (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    color character varying DEFAULT '#0B6E6E'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: vehicle_teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_teams_id_seq OWNED BY public.vehicle_teams.id;


--
-- Name: vehicle_type_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_type_requests (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    seats integer NOT NULL,
    reason text,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    requested_by_id bigint,
    decided_by_id bigint,
    decided_at timestamp(6) without time zone,
    vehicle_type_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT vehicle_type_requests_status CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('added'::character varying)::text, ('declined'::character varying)::text])))
);


--
-- Name: vehicle_type_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_type_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_type_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_type_requests_id_seq OWNED BY public.vehicle_type_requests.id;


--
-- Name: vehicle_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_types (
    id bigint NOT NULL,
    key character varying NOT NULL,
    name character varying NOT NULL,
    seats integer NOT NULL,
    tyre_layout character varying DEFAULT '1-1'::character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    custom boolean DEFAULT false NOT NULL
);


--
-- Name: vehicle_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicle_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicle_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicle_types_id_seq OWNED BY public.vehicle_types.id;


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    operator_id bigint,
    vehicle_team_id bigint,
    plate character varying NOT NULL,
    seats integer,
    make character varying,
    model character varying,
    year_made integer,
    tags character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    notes text,
    photo character varying,
    driver_name character varying,
    driver_phone character varying,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    chassis_number character varying,
    engine_number character varying,
    registered_on date,
    coe_expires_on date,
    road_tax_expires_on date,
    source character varying DEFAULT 'console'::character varying NOT NULL
);


--
-- Name: vehicles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vehicles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vehicles_id_seq OWNED BY public.vehicles.id;


--
-- Name: workshops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workshops (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name character varying NOT NULL,
    address text,
    phone character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: workshops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workshops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workshops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workshops_id_seq OWNED BY public.workshops.id;


--
-- Name: occurrence_positions_y2026m09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions ATTACH PARTITION public.occurrence_positions_y2026m09 FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');


--
-- Name: occurrence_positions_y2026m10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions ATTACH PARTITION public.occurrence_positions_y2026m10 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');


--
-- Name: occurrence_positions_y2026m11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions ATTACH PARTITION public.occurrence_positions_y2026m11 FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');


--
-- Name: occurrence_positions_y2026m12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions ATTACH PARTITION public.occurrence_positions_y2026m12 FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');


--
-- Name: occurrence_positions_y2027m01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions ATTACH PARTITION public.occurrence_positions_y2027m01 FOR VALUES FROM ('2027-01-01') TO ('2027-02-01');


--
-- Name: occurrence_positions_y2027m02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions ATTACH PARTITION public.occurrence_positions_y2027m02 FOR VALUES FROM ('2027-02-01') TO ('2027-03-01');


--
-- Name: occurrence_positions_y2027m03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions ATTACH PARTITION public.occurrence_positions_y2027m03 FOR VALUES FROM ('2027-03-01') TO ('2027-04-01');


--
-- Name: trip_occurrences_y2026m09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences ATTACH PARTITION public.trip_occurrences_y2026m09 FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');


--
-- Name: trip_occurrences_y2026m10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences ATTACH PARTITION public.trip_occurrences_y2026m10 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');


--
-- Name: trip_occurrences_y2026m11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences ATTACH PARTITION public.trip_occurrences_y2026m11 FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');


--
-- Name: trip_occurrences_y2026m12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences ATTACH PARTITION public.trip_occurrences_y2026m12 FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');


--
-- Name: trip_occurrences_y2027m01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences ATTACH PARTITION public.trip_occurrences_y2027m01 FOR VALUES FROM ('2027-01-01') TO ('2027-02-01');


--
-- Name: trip_occurrences_y2027m02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences ATTACH PARTITION public.trip_occurrences_y2027m02 FOR VALUES FROM ('2027-02-01') TO ('2027-03-01');


--
-- Name: trip_occurrences_y2027m03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences ATTACH PARTITION public.trip_occurrences_y2027m03 FOR VALUES FROM ('2027-03-01') TO ('2027-04-01');


--
-- Name: academic_terms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_terms ALTER COLUMN id SET DEFAULT nextval('public.academic_terms_id_seq'::regclass);


--
-- Name: academic_years id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_years ALTER COLUMN id SET DEFAULT nextval('public.academic_years_id_seq'::regclass);


--
-- Name: allowlisted_jwts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allowlisted_jwts ALTER COLUMN id SET DEFAULT nextval('public.allowlisted_jwts_id_seq'::regclass);


--
-- Name: attendants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendants ALTER COLUMN id SET DEFAULT nextval('public.attendants_id_seq'::regclass);


--
-- Name: audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audits ALTER COLUMN id SET DEFAULT nextval('public.audits_id_seq'::regclass);


--
-- Name: bank_branches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_branches ALTER COLUMN id SET DEFAULT nextval('public.bank_branches_id_seq'::regclass);


--
-- Name: banks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banks ALTER COLUMN id SET DEFAULT nextval('public.banks_id_seq'::regclass);


--
-- Name: booking_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_attachments ALTER COLUMN id SET DEFAULT nextval('public.booking_attachments_id_seq'::regclass);


--
-- Name: booking_cancel_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_cancel_requests ALTER COLUMN id SET DEFAULT nextval('public.booking_cancel_requests_id_seq'::regclass);


--
-- Name: booking_days id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_days ALTER COLUMN id SET DEFAULT nextval('public.booking_days_id_seq'::regclass);


--
-- Name: booking_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_events ALTER COLUMN id SET DEFAULT nextval('public.booking_events_id_seq'::regclass);


--
-- Name: booking_trip_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_changes ALTER COLUMN id SET DEFAULT nextval('public.booking_trip_changes_id_seq'::regclass);


--
-- Name: booking_trip_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_points ALTER COLUMN id SET DEFAULT nextval('public.booking_trip_points_id_seq'::regclass);


--
-- Name: booking_trip_standbys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_standbys ALTER COLUMN id SET DEFAULT nextval('public.booking_trip_standbys_id_seq'::regclass);


--
-- Name: booking_trip_vehicles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_vehicles ALTER COLUMN id SET DEFAULT nextval('public.booking_trip_vehicles_id_seq'::regclass);


--
-- Name: booking_trips id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trips ALTER COLUMN id SET DEFAULT nextval('public.booking_trips_id_seq'::regclass);


--
-- Name: bookings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings ALTER COLUMN id SET DEFAULT nextval('public.bookings_id_seq'::regclass);


--
-- Name: bus_request_answer_moves id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_answer_moves ALTER COLUMN id SET DEFAULT nextval('public.bus_request_answer_moves_id_seq'::regclass);


--
-- Name: bus_request_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_events ALTER COLUMN id SET DEFAULT nextval('public.bus_request_events_id_seq'::regclass);


--
-- Name: bus_request_places id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_places ALTER COLUMN id SET DEFAULT nextval('public.bus_request_places_id_seq'::regclass);


--
-- Name: bus_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests ALTER COLUMN id SET DEFAULT nextval('public.bus_requests_id_seq'::regclass);


--
-- Name: bus_session_variants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_session_variants ALTER COLUMN id SET DEFAULT nextval('public.bus_session_variants_id_seq'::regclass);


--
-- Name: bus_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_sessions ALTER COLUMN id SET DEFAULT nextval('public.bus_sessions_id_seq'::regclass);


--
-- Name: calendar_days id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_days ALTER COLUMN id SET DEFAULT nextval('public.calendar_days_id_seq'::regclass);


--
-- Name: calendars id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendars ALTER COLUMN id SET DEFAULT nextval('public.calendars_id_seq'::regclass);


--
-- Name: cca_bookings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_bookings ALTER COLUMN id SET DEFAULT nextval('public.cca_bookings_id_seq'::regclass);


--
-- Name: cca_credits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_credits ALTER COLUMN id SET DEFAULT nextval('public.cca_credits_id_seq'::regclass);


--
-- Name: cca_off_days id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_off_days ALTER COLUMN id SET DEFAULT nextval('public.cca_off_days_id_seq'::regclass);


--
-- Name: cca_ride_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_ride_settings ALTER COLUMN id SET DEFAULT nextval('public.cca_ride_settings_id_seq'::regclass);


--
-- Name: client_billing_contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_billing_contacts ALTER COLUMN id SET DEFAULT nextval('public.client_billing_contacts_id_seq'::regclass);


--
-- Name: client_bookable_vehicle_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_bookable_vehicle_types ALTER COLUMN id SET DEFAULT nextval('public.client_bookable_vehicle_types_id_seq'::regclass);


--
-- Name: client_end_customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_end_customers ALTER COLUMN id SET DEFAULT nextval('public.client_end_customers_id_seq'::regclass);


--
-- Name: client_invoice_line_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_line_runs ALTER COLUMN id SET DEFAULT nextval('public.client_invoice_line_runs_id_seq'::regclass);


--
-- Name: client_invoice_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_lines ALTER COLUMN id SET DEFAULT nextval('public.client_invoice_lines_id_seq'::regclass);


--
-- Name: client_invoice_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_payments ALTER COLUMN id SET DEFAULT nextval('public.client_invoice_payments_id_seq'::regclass);


--
-- Name: client_invoice_sends id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_sends ALTER COLUMN id SET DEFAULT nextval('public.client_invoice_sends_id_seq'::regclass);


--
-- Name: client_invoices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices ALTER COLUMN id SET DEFAULT nextval('public.client_invoices_id_seq'::regclass);


--
-- Name: client_pickup_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_pickup_points ALTER COLUMN id SET DEFAULT nextval('public.client_pickup_points_id_seq'::regclass);


--
-- Name: client_sites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_sites ALTER COLUMN id SET DEFAULT nextval('public.client_sites_id_seq'::regclass);


--
-- Name: client_user_sites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_user_sites ALTER COLUMN id SET DEFAULT nextval('public.client_user_sites_id_seq'::regclass);


--
-- Name: client_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_users ALTER COLUMN id SET DEFAULT nextval('public.client_users_id_seq'::regclass);


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: company_country_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_country_requests ALTER COLUMN id SET DEFAULT nextval('public.company_country_requests_id_seq'::regclass);


--
-- Name: company_lead_domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_lead_domains ALTER COLUMN id SET DEFAULT nextval('public.company_lead_domains_id_seq'::regclass);


--
-- Name: company_leads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_leads ALTER COLUMN id SET DEFAULT nextval('public.company_leads_id_seq'::regclass);


--
-- Name: company_sequences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_sequences ALTER COLUMN id SET DEFAULT nextval('public.company_sequences_id_seq'::regclass);


--
-- Name: dashboard_layouts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_layouts ALTER COLUMN id SET DEFAULT nextval('public.dashboard_layouts_id_seq'::regclass);


--
-- Name: disabled_vehicle_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_vehicle_types ALTER COLUMN id SET DEFAULT nextval('public.disabled_vehicle_types_id_seq'::regclass);


--
-- Name: discover_advertisers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discover_advertisers ALTER COLUMN id SET DEFAULT nextval('public.discover_advertisers_id_seq'::regclass);


--
-- Name: discover_placements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discover_placements ALTER COLUMN id SET DEFAULT nextval('public.discover_placements_id_seq'::regclass);


--
-- Name: document_reads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_reads ALTER COLUMN id SET DEFAULT nextval('public.document_reads_id_seq'::regclass);


--
-- Name: driver_app_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_app_sessions ALTER COLUMN id SET DEFAULT nextval('public.driver_app_sessions_id_seq'::regclass);


--
-- Name: driver_invites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_invites ALTER COLUMN id SET DEFAULT nextval('public.driver_invites_id_seq'::regclass);


--
-- Name: driver_kyc_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_kyc_profiles ALTER COLUMN id SET DEFAULT nextval('public.driver_kyc_profiles_id_seq'::regclass);


--
-- Name: driver_pay_month_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_month_lines ALTER COLUMN id SET DEFAULT nextval('public.driver_pay_month_lines_id_seq'::regclass);


--
-- Name: driver_pay_month_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_month_runs ALTER COLUMN id SET DEFAULT nextval('public.driver_pay_month_runs_id_seq'::regclass);


--
-- Name: driver_pay_months id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_months ALTER COLUMN id SET DEFAULT nextval('public.driver_pay_months_id_seq'::regclass);


--
-- Name: driver_pay_schemes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_schemes ALTER COLUMN id SET DEFAULT nextval('public.driver_pay_schemes_id_seq'::regclass);


--
-- Name: driver_point_allocations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_allocations ALTER COLUMN id SET DEFAULT nextval('public.driver_point_allocations_id_seq'::regclass);


--
-- Name: driver_point_deductions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_deductions ALTER COLUMN id SET DEFAULT nextval('public.driver_point_deductions_id_seq'::regclass);


--
-- Name: driver_point_lots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_lots ALTER COLUMN id SET DEFAULT nextval('public.driver_point_lots_id_seq'::regclass);


--
-- Name: driver_vehicle_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_vehicle_types ALTER COLUMN id SET DEFAULT nextval('public.driver_vehicle_types_id_seq'::regclass);


--
-- Name: drivers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers ALTER COLUMN id SET DEFAULT nextval('public.drivers_id_seq'::regclass);


--
-- Name: external_vehicle_share_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_share_links ALTER COLUMN id SET DEFAULT nextval('public.external_vehicle_share_links_id_seq'::regclass);


--
-- Name: external_vehicle_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_submissions ALTER COLUMN id SET DEFAULT nextval('public.external_vehicle_submissions_id_seq'::regclass);


--
-- Name: families id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.families ALTER COLUMN id SET DEFAULT nextval('public.families_id_seq'::regclass);


--
-- Name: family_guardians id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_guardians ALTER COLUMN id SET DEFAULT nextval('public.family_guardians_id_seq'::regclass);


--
-- Name: family_riders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_riders ALTER COLUMN id SET DEFAULT nextval('public.family_riders_id_seq'::regclass);


--
-- Name: fare_adjustments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_adjustments ALTER COLUMN id SET DEFAULT nextval('public.fare_adjustments_id_seq'::regclass);


--
-- Name: fare_bus_rates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_bus_rates ALTER COLUMN id SET DEFAULT nextval('public.fare_bus_rates_id_seq'::regclass);


--
-- Name: fare_size_columns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_size_columns ALTER COLUMN id SET DEFAULT nextval('public.fare_size_columns_id_seq'::regclass);


--
-- Name: fare_surcharges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_surcharges ALTER COLUMN id SET DEFAULT nextval('public.fare_surcharges_id_seq'::regclass);


--
-- Name: fare_tables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tables ALTER COLUMN id SET DEFAULT nextval('public.fare_tables_id_seq'::regclass);


--
-- Name: fare_tier_sizes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tier_sizes ALTER COLUMN id SET DEFAULT nextval('public.fare_tier_sizes_id_seq'::regclass);


--
-- Name: fare_tiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tiers ALTER COLUMN id SET DEFAULT nextval('public.fare_tiers_id_seq'::regclass);


--
-- Name: feasibility_bus_prices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_bus_prices ALTER COLUMN id SET DEFAULT nextval('public.feasibility_bus_prices_id_seq'::regclass);


--
-- Name: feasibility_fare_tiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_fare_tiers ALTER COLUMN id SET DEFAULT nextval('public.feasibility_fare_tiers_id_seq'::regclass);


--
-- Name: feasibility_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_rows ALTER COLUMN id SET DEFAULT nextval('public.feasibility_rows_id_seq'::regclass);


--
-- Name: feasibility_scenarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_scenarios ALTER COLUMN id SET DEFAULT nextval('public.feasibility_scenarios_id_seq'::regclass);


--
-- Name: feasibility_studies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_studies ALTER COLUMN id SET DEFAULT nextval('public.feasibility_studies_id_seq'::regclass);


--
-- Name: finance_approvers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_approvers ALTER COLUMN id SET DEFAULT nextval('public.finance_approvers_id_seq'::regclass);


--
-- Name: finance_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_settings ALTER COLUMN id SET DEFAULT nextval('public.finance_settings_id_seq'::regclass);


--
-- Name: fuel_alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_alerts ALTER COLUMN id SET DEFAULT nextval('public.fuel_alerts_id_seq'::regclass);


--
-- Name: fuel_companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_companies ALTER COLUMN id SET DEFAULT nextval('public.fuel_companies_id_seq'::regclass);


--
-- Name: fuel_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_entries ALTER COLUMN id SET DEFAULT nextval('public.fuel_entries_id_seq'::regclass);


--
-- Name: maintenance_invoices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_invoices ALTER COLUMN id SET DEFAULT nextval('public.maintenance_invoices_id_seq'::regclass);


--
-- Name: maintenance_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_lines ALTER COLUMN id SET DEFAULT nextval('public.maintenance_lines_id_seq'::regclass);


--
-- Name: maintenance_visits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_visits ALTER COLUMN id SET DEFAULT nextval('public.maintenance_visits_id_seq'::regclass);


--
-- Name: message_terms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_terms ALTER COLUMN id SET DEFAULT nextval('public.message_terms_id_seq'::regclass);


--
-- Name: notice_deliveries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_deliveries ALTER COLUMN id SET DEFAULT nextval('public.notice_deliveries_id_seq'::regclass);


--
-- Name: notice_routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_routes ALTER COLUMN id SET DEFAULT nextval('public.notice_routes_id_seq'::regclass);


--
-- Name: notice_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_runs ALTER COLUMN id SET DEFAULT nextval('public.notice_runs_id_seq'::regclass);


--
-- Name: notice_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_templates ALTER COLUMN id SET DEFAULT nextval('public.notice_templates_id_seq'::regclass);


--
-- Name: notices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices ALTER COLUMN id SET DEFAULT nextval('public.notices_id_seq'::regclass);


--
-- Name: notification_emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_emails ALTER COLUMN id SET DEFAULT nextval('public.notification_emails_id_seq'::regclass);


--
-- Name: occurrence_correction_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_logs ALTER COLUMN id SET DEFAULT nextval('public.occurrence_correction_logs_id_seq'::regclass);


--
-- Name: occurrence_correction_stops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_stops ALTER COLUMN id SET DEFAULT nextval('public.occurrence_correction_stops_id_seq'::regclass);


--
-- Name: occurrence_corrections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_corrections ALTER COLUMN id SET DEFAULT nextval('public.occurrence_corrections_id_seq'::regclass);


--
-- Name: occurrence_driver_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_driver_reports ALTER COLUMN id SET DEFAULT nextval('public.occurrence_driver_reports_id_seq'::regclass);


--
-- Name: occurrence_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_notes ALTER COLUMN id SET DEFAULT nextval('public.occurrence_notes_id_seq'::regclass);


--
-- Name: occurrence_report_photos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_report_photos ALTER COLUMN id SET DEFAULT nextval('public.occurrence_report_photos_id_seq'::regclass);


--
-- Name: occurrence_stop_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_stop_events ALTER COLUMN id SET DEFAULT nextval('public.occurrence_stop_events_id_seq'::regclass);


--
-- Name: occurrence_trip_summaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_trip_summaries ALTER COLUMN id SET DEFAULT nextval('public.occurrence_trip_summaries_id_seq'::regclass);


--
-- Name: operator_cost_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_cost_overrides ALTER COLUMN id SET DEFAULT nextval('public.operator_cost_overrides_id_seq'::regclass);


--
-- Name: operator_drivers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers ALTER COLUMN id SET DEFAULT nextval('public.operator_drivers_id_seq'::regclass);


--
-- Name: operator_pay_batch_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batch_lines ALTER COLUMN id SET DEFAULT nextval('public.operator_pay_batch_lines_id_seq'::regclass);


--
-- Name: operator_pay_batch_operators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batch_operators ALTER COLUMN id SET DEFAULT nextval('public.operator_pay_batch_operators_id_seq'::regclass);


--
-- Name: operator_pay_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batches ALTER COLUMN id SET DEFAULT nextval('public.operator_pay_batches_id_seq'::regclass);


--
-- Name: operator_pay_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_items ALTER COLUMN id SET DEFAULT nextval('public.operator_pay_items_id_seq'::regclass);


--
-- Name: operator_pay_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_payments ALTER COLUMN id SET DEFAULT nextval('public.operator_pay_payments_id_seq'::regclass);


--
-- Name: operators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators ALTER COLUMN id SET DEFAULT nextval('public.operators_id_seq'::regclass);


--
-- Name: ops_alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ops_alerts ALTER COLUMN id SET DEFAULT nextval('public.ops_alerts_id_seq'::regclass);


--
-- Name: pay_bonus_drivers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_drivers ALTER COLUMN id SET DEFAULT nextval('public.pay_bonus_drivers_id_seq'::regclass);


--
-- Name: pay_bonus_excluded_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_excluded_periods ALTER COLUMN id SET DEFAULT nextval('public.pay_bonus_excluded_periods_id_seq'::regclass);


--
-- Name: pay_bonus_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_payments ALTER COLUMN id SET DEFAULT nextval('public.pay_bonus_payments_id_seq'::regclass);


--
-- Name: pay_bonus_schemes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_schemes ALTER COLUMN id SET DEFAULT nextval('public.pay_bonus_schemes_id_seq'::regclass);


--
-- Name: pay_bonus_tiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_tiers ALTER COLUMN id SET DEFAULT nextval('public.pay_bonus_tiers_id_seq'::regclass);


--
-- Name: pay_bonuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonuses ALTER COLUMN id SET DEFAULT nextval('public.pay_bonuses_id_seq'::regclass);


--
-- Name: pay_rate_period_ranges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_period_ranges ALTER COLUMN id SET DEFAULT nextval('public.pay_rate_period_ranges_id_seq'::regclass);


--
-- Name: pay_rate_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_periods ALTER COLUMN id SET DEFAULT nextval('public.pay_rate_periods_id_seq'::regclass);


--
-- Name: pay_rate_plan_vehicle_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_plan_vehicle_types ALTER COLUMN id SET DEFAULT nextval('public.pay_rate_plan_vehicle_types_id_seq'::regclass);


--
-- Name: pay_rate_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_plans ALTER COLUMN id SET DEFAULT nextval('public.pay_rate_plans_id_seq'::regclass);


--
-- Name: pay_rates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rates ALTER COLUMN id SET DEFAULT nextval('public.pay_rates_id_seq'::regclass);


--
-- Name: pay_rewards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rewards ALTER COLUMN id SET DEFAULT nextval('public.pay_rewards_id_seq'::regclass);


--
-- Name: pay_scheme_route_bands id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_route_bands ALTER COLUMN id SET DEFAULT nextval('public.pay_scheme_route_bands_id_seq'::regclass);


--
-- Name: pay_scheme_target_tiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_target_tiers ALTER COLUMN id SET DEFAULT nextval('public.pay_scheme_target_tiers_id_seq'::regclass);


--
-- Name: pay_scheme_volume_tiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_volume_tiers ALTER COLUMN id SET DEFAULT nextval('public.pay_scheme_volume_tiers_id_seq'::regclass);


--
-- Name: pay_schemes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_schemes ALTER COLUMN id SET DEFAULT nextval('public.pay_schemes_id_seq'::regclass);


--
-- Name: pay_simulator_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_simulator_templates ALTER COLUMN id SET DEFAULT nextval('public.pay_simulator_templates_id_seq'::regclass);


--
-- Name: pickup_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pickup_points ALTER COLUMN id SET DEFAULT nextval('public.pickup_points_id_seq'::regclass);


--
-- Name: plan_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_comments ALTER COLUMN id SET DEFAULT nextval('public.plan_comments_id_seq'::regclass);


--
-- Name: policy_reminders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_reminders ALTER COLUMN id SET DEFAULT nextval('public.policy_reminders_id_seq'::regclass);


--
-- Name: portal_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_accounts ALTER COLUMN id SET DEFAULT nextval('public.portal_accounts_id_seq'::regclass);


--
-- Name: portal_jwts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_jwts ALTER COLUMN id SET DEFAULT nextval('public.portal_jwts_id_seq'::regclass);


--
-- Name: portal_sign_in_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_sign_in_codes ALTER COLUMN id SET DEFAULT nextval('public.portal_sign_in_codes_id_seq'::regclass);


--
-- Name: postal_geocodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postal_geocodes ALTER COLUMN id SET DEFAULT nextval('public.postal_geocodes_id_seq'::regclass);


--
-- Name: public_holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_holidays ALTER COLUMN id SET DEFAULT nextval('public.public_holidays_id_seq'::regclass);


--
-- Name: rate_card_amounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_amounts ALTER COLUMN id SET DEFAULT nextval('public.rate_card_amounts_id_seq'::regclass);


--
-- Name: rate_card_distance_bands id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_distance_bands ALTER COLUMN id SET DEFAULT nextval('public.rate_card_distance_bands_id_seq'::regclass);


--
-- Name: rate_card_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_periods ALTER COLUMN id SET DEFAULT nextval('public.rate_card_periods_id_seq'::regclass);


--
-- Name: rate_card_ranges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_ranges ALTER COLUMN id SET DEFAULT nextval('public.rate_card_ranges_id_seq'::regclass);


--
-- Name: rate_card_rates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_rates ALTER COLUMN id SET DEFAULT nextval('public.rate_card_rates_id_seq'::regclass);


--
-- Name: rate_card_vehicle_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_vehicle_types ALTER COLUMN id SET DEFAULT nextval('public.rate_card_vehicle_types_id_seq'::regclass);


--
-- Name: rate_cards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_cards ALTER COLUMN id SET DEFAULT nextval('public.rate_cards_id_seq'::regclass);


--
-- Name: registration_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registration_messages ALTER COLUMN id SET DEFAULT nextval('public.registration_messages_id_seq'::regclass);


--
-- Name: replacement_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_notifications ALTER COLUMN id SET DEFAULT nextval('public.replacement_notifications_id_seq'::regclass);


--
-- Name: replacements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements ALTER COLUMN id SET DEFAULT nextval('public.replacements_id_seq'::regclass);


--
-- Name: rider_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_assignments ALTER COLUMN id SET DEFAULT nextval('public.rider_assignments_id_seq'::regclass);


--
-- Name: rider_datasets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_datasets ALTER COLUMN id SET DEFAULT nextval('public.rider_datasets_id_seq'::regclass);


--
-- Name: rider_point_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_point_links ALTER COLUMN id SET DEFAULT nextval('public.rider_point_links_id_seq'::regclass);


--
-- Name: route_charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_charges ALTER COLUMN id SET DEFAULT nextval('public.route_charges_id_seq'::regclass);


--
-- Name: route_list_version_stops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_version_stops ALTER COLUMN id SET DEFAULT nextval('public.route_list_version_stops_id_seq'::regclass);


--
-- Name: route_list_version_students id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_version_students ALTER COLUMN id SET DEFAULT nextval('public.route_list_version_students_id_seq'::regclass);


--
-- Name: route_list_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_versions ALTER COLUMN id SET DEFAULT nextval('public.route_list_versions_id_seq'::regclass);


--
-- Name: routing_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_runs ALTER COLUMN id SET DEFAULT nextval('public.routing_runs_id_seq'::regclass);


--
-- Name: routing_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_settings ALTER COLUMN id SET DEFAULT nextval('public.routing_settings_id_seq'::regclass);


--
-- Name: school_attendant_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_attendant_policies ALTER COLUMN id SET DEFAULT nextval('public.school_attendant_policies_id_seq'::regclass);


--
-- Name: school_bill_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bill_lines ALTER COLUMN id SET DEFAULT nextval('public.school_bill_lines_id_seq'::regclass);


--
-- Name: school_bills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills ALTER COLUMN id SET DEFAULT nextval('public.school_bills_id_seq'::regclass);


--
-- Name: school_bus_size_rates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bus_size_rates ALTER COLUMN id SET DEFAULT nextval('public.school_bus_size_rates_id_seq'::regclass);


--
-- Name: school_holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_holidays ALTER COLUMN id SET DEFAULT nextval('public.school_holidays_id_seq'::regclass);


--
-- Name: school_levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_levels ALTER COLUMN id SET DEFAULT nextval('public.school_levels_id_seq'::regclass);


--
-- Name: school_operator_pays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_operator_pays ALTER COLUMN id SET DEFAULT nextval('public.school_operator_pays_id_seq'::regclass);


--
-- Name: school_payment_methods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_payment_methods ALTER COLUMN id SET DEFAULT nextval('public.school_payment_methods_id_seq'::regclass);


--
-- Name: school_plan_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plan_changes ALTER COLUMN id SET DEFAULT nextval('public.school_plan_changes_id_seq'::regclass);


--
-- Name: school_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plans ALTER COLUMN id SET DEFAULT nextval('public.school_plans_id_seq'::regclass);


--
-- Name: school_policy_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_policy_versions ALTER COLUMN id SET DEFAULT nextval('public.school_policy_versions_id_seq'::regclass);


--
-- Name: school_registrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_registrations ALTER COLUMN id SET DEFAULT nextval('public.school_registrations_id_seq'::regclass);


--
-- Name: school_riders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_riders ALTER COLUMN id SET DEFAULT nextval('public.school_riders_id_seq'::regclass);


--
-- Name: school_route_labels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_labels ALTER COLUMN id SET DEFAULT nextval('public.school_route_labels_id_seq'::regclass);


--
-- Name: school_route_prices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_prices ALTER COLUMN id SET DEFAULT nextval('public.school_route_prices_id_seq'::regclass);


--
-- Name: school_route_replacements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_replacements ALTER COLUMN id SET DEFAULT nextval('public.school_route_replacements_id_seq'::regclass);


--
-- Name: school_route_riders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_riders ALTER COLUMN id SET DEFAULT nextval('public.school_route_riders_id_seq'::regclass);


--
-- Name: school_route_stops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_stops ALTER COLUMN id SET DEFAULT nextval('public.school_route_stops_id_seq'::regclass);


--
-- Name: school_route_vehicle_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_vehicle_changes ALTER COLUMN id SET DEFAULT nextval('public.school_route_vehicle_changes_id_seq'::regclass);


--
-- Name: school_routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_routes ALTER COLUMN id SET DEFAULT nextval('public.school_routes_id_seq'::regclass);


--
-- Name: school_special_days id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_special_days ALTER COLUMN id SET DEFAULT nextval('public.school_special_days_id_seq'::regclass);


--
-- Name: school_stops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_stops ALTER COLUMN id SET DEFAULT nextval('public.school_stops_id_seq'::regclass);


--
-- Name: schools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools ALTER COLUMN id SET DEFAULT nextval('public.schools_id_seq'::regclass);


--
-- Name: setup_locks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setup_locks ALTER COLUMN id SET DEFAULT nextval('public.setup_locks_id_seq'::regclass);


--
-- Name: stop_photo_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_requests ALTER COLUMN id SET DEFAULT nextval('public.stop_photo_requests_id_seq'::regclass);


--
-- Name: stop_photo_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_submissions ALTER COLUMN id SET DEFAULT nextval('public.stop_photo_submissions_id_seq'::regclass);


--
-- Name: stop_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_points ALTER COLUMN id SET DEFAULT nextval('public.stop_points_id_seq'::regclass);


--
-- Name: stops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stops ALTER COLUMN id SET DEFAULT nextval('public.stops_id_seq'::regclass);


--
-- Name: student_attendances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances ALTER COLUMN id SET DEFAULT nextval('public.student_attendances_id_seq'::regclass);


--
-- Name: tracking_devices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_devices ALTER COLUMN id SET DEFAULT nextval('public.tracking_devices_id_seq'::regclass);


--
-- Name: tracking_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_links ALTER COLUMN id SET DEFAULT nextval('public.tracking_links_id_seq'::regclass);


--
-- Name: trip_assignment_slots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignment_slots ALTER COLUMN id SET DEFAULT nextval('public.trip_assignment_slots_id_seq'::regclass);


--
-- Name: trip_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignments ALTER COLUMN id SET DEFAULT nextval('public.trip_assignments_id_seq'::regclass);


--
-- Name: trip_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_attachments ALTER COLUMN id SET DEFAULT nextval('public.trip_attachments_id_seq'::regclass);


--
-- Name: trip_price_cells id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_price_cells ALTER COLUMN id SET DEFAULT nextval('public.trip_price_cells_id_seq'::regclass);


--
-- Name: trip_route_vias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_route_vias ALTER COLUMN id SET DEFAULT nextval('public.trip_route_vias_id_seq'::regclass);


--
-- Name: trip_run_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_groups ALTER COLUMN id SET DEFAULT nextval('public.trip_run_groups_id_seq'::regclass);


--
-- Name: trip_run_slots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_slots ALTER COLUMN id SET DEFAULT nextval('public.trip_run_slots_id_seq'::regclass);


--
-- Name: trip_run_times id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_times ALTER COLUMN id SET DEFAULT nextval('public.trip_run_times_id_seq'::regclass);


--
-- Name: trip_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_runs ALTER COLUMN id SET DEFAULT nextval('public.trip_runs_id_seq'::regclass);


--
-- Name: trip_standby_photos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_standby_photos ALTER COLUMN id SET DEFAULT nextval('public.trip_standby_photos_id_seq'::regclass);


--
-- Name: trip_standbys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_standbys ALTER COLUMN id SET DEFAULT nextval('public.trip_standbys_id_seq'::regclass);


--
-- Name: trip_stop_photos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_photos ALTER COLUMN id SET DEFAULT nextval('public.trip_stop_photos_id_seq'::regclass);


--
-- Name: trip_stop_students id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_students ALTER COLUMN id SET DEFAULT nextval('public.trip_stop_students_id_seq'::regclass);


--
-- Name: trip_stops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops ALTER COLUMN id SET DEFAULT nextval('public.trip_stops_id_seq'::regclass);


--
-- Name: trip_time_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_time_changes ALTER COLUMN id SET DEFAULT nextval('public.trip_time_changes_id_seq'::regclass);


--
-- Name: trip_vehicle_requirements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_requirements ALTER COLUMN id SET DEFAULT nextval('public.trip_vehicle_requirements_id_seq'::regclass);


--
-- Name: trip_vehicle_slots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_slots ALTER COLUMN id SET DEFAULT nextval('public.trip_vehicle_slots_id_seq'::regclass);


--
-- Name: trips id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips ALTER COLUMN id SET DEFAULT nextval('public.trips_id_seq'::regclass);


--
-- Name: ura_subzones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ura_subzones ALTER COLUMN id SET DEFAULT nextval('public.ura_subzones_id_seq'::regclass);


--
-- Name: user_notification_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notification_preferences ALTER COLUMN id SET DEFAULT nextval('public.user_notification_preferences_id_seq'::regclass);


--
-- Name: user_schools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_schools ALTER COLUMN id SET DEFAULT nextval('public.user_schools_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vehicle_cost_spike_acks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_cost_spike_acks ALTER COLUMN id SET DEFAULT nextval('public.vehicle_cost_spike_acks_id_seq'::regclass);


--
-- Name: vehicle_driver_schedules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules ALTER COLUMN id SET DEFAULT nextval('public.vehicle_driver_schedules_id_seq'::regclass);


--
-- Name: vehicle_finance_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_finance_entries ALTER COLUMN id SET DEFAULT nextval('public.vehicle_finance_entries_id_seq'::regclass);


--
-- Name: vehicle_financials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_financials ALTER COLUMN id SET DEFAULT nextval('public.vehicle_financials_id_seq'::regclass);


--
-- Name: vehicle_insurance_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_insurance_documents ALTER COLUMN id SET DEFAULT nextval('public.vehicle_insurance_documents_id_seq'::regclass);


--
-- Name: vehicle_insurance_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_insurance_policies ALTER COLUMN id SET DEFAULT nextval('public.vehicle_insurance_policies_id_seq'::regclass);


--
-- Name: vehicle_live_positions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_live_positions ALTER COLUMN id SET DEFAULT nextval('public.vehicle_live_positions_id_seq'::regclass);


--
-- Name: vehicle_loan_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_loan_payments ALTER COLUMN id SET DEFAULT nextval('public.vehicle_loan_payments_id_seq'::regclass);


--
-- Name: vehicle_log_cards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_log_cards ALTER COLUMN id SET DEFAULT nextval('public.vehicle_log_cards_id_seq'::regclass);


--
-- Name: vehicle_teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_teams ALTER COLUMN id SET DEFAULT nextval('public.vehicle_teams_id_seq'::regclass);


--
-- Name: vehicle_type_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_type_requests ALTER COLUMN id SET DEFAULT nextval('public.vehicle_type_requests_id_seq'::regclass);


--
-- Name: vehicle_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_types ALTER COLUMN id SET DEFAULT nextval('public.vehicle_types_id_seq'::regclass);


--
-- Name: vehicles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles ALTER COLUMN id SET DEFAULT nextval('public.vehicles_id_seq'::regclass);


--
-- Name: workshops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workshops ALTER COLUMN id SET DEFAULT nextval('public.workshops_id_seq'::regclass);


--
-- Name: academic_terms academic_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_terms
    ADD CONSTRAINT academic_terms_pkey PRIMARY KEY (id);


--
-- Name: academic_years academic_years_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT academic_years_pkey PRIMARY KEY (id);


--
-- Name: allowlisted_jwts allowlisted_jwts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allowlisted_jwts
    ADD CONSTRAINT allowlisted_jwts_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attendants attendants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendants
    ADD CONSTRAINT attendants_pkey PRIMARY KEY (id);


--
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: bank_branches bank_branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_branches
    ADD CONSTRAINT bank_branches_pkey PRIMARY KEY (id);


--
-- Name: banks banks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banks
    ADD CONSTRAINT banks_pkey PRIMARY KEY (id);


--
-- Name: booking_attachments booking_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_attachments
    ADD CONSTRAINT booking_attachments_pkey PRIMARY KEY (id);


--
-- Name: booking_cancel_requests booking_cancel_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_cancel_requests
    ADD CONSTRAINT booking_cancel_requests_pkey PRIMARY KEY (id);


--
-- Name: booking_days booking_days_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_days
    ADD CONSTRAINT booking_days_pkey PRIMARY KEY (id);


--
-- Name: booking_events booking_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_events
    ADD CONSTRAINT booking_events_pkey PRIMARY KEY (id);


--
-- Name: booking_trip_changes booking_trip_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_changes
    ADD CONSTRAINT booking_trip_changes_pkey PRIMARY KEY (id);


--
-- Name: booking_trip_points booking_trip_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_points
    ADD CONSTRAINT booking_trip_points_pkey PRIMARY KEY (id);


--
-- Name: booking_trip_standbys booking_trip_standbys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_standbys
    ADD CONSTRAINT booking_trip_standbys_pkey PRIMARY KEY (id);


--
-- Name: booking_trip_vehicles booking_trip_vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_vehicles
    ADD CONSTRAINT booking_trip_vehicles_pkey PRIMARY KEY (id);


--
-- Name: booking_trips booking_trips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trips
    ADD CONSTRAINT booking_trips_pkey PRIMARY KEY (id);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: bus_request_answer_moves bus_request_answer_moves_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_answer_moves
    ADD CONSTRAINT bus_request_answer_moves_pkey PRIMARY KEY (id);


--
-- Name: bus_request_events bus_request_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_events
    ADD CONSTRAINT bus_request_events_pkey PRIMARY KEY (id);


--
-- Name: bus_request_places bus_request_places_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_places
    ADD CONSTRAINT bus_request_places_pkey PRIMARY KEY (id);


--
-- Name: bus_requests bus_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT bus_requests_pkey PRIMARY KEY (id);


--
-- Name: bus_session_variants bus_session_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_session_variants
    ADD CONSTRAINT bus_session_variants_pkey PRIMARY KEY (id);


--
-- Name: bus_sessions bus_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_sessions
    ADD CONSTRAINT bus_sessions_pkey PRIMARY KEY (id);


--
-- Name: calendar_days calendar_days_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_days
    ADD CONSTRAINT calendar_days_pkey PRIMARY KEY (id);


--
-- Name: calendars calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendars
    ADD CONSTRAINT calendars_pkey PRIMARY KEY (id);


--
-- Name: cca_bookings cca_bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_bookings
    ADD CONSTRAINT cca_bookings_pkey PRIMARY KEY (id);


--
-- Name: cca_credits cca_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_credits
    ADD CONSTRAINT cca_credits_pkey PRIMARY KEY (id);


--
-- Name: cca_off_days cca_off_days_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_off_days
    ADD CONSTRAINT cca_off_days_pkey PRIMARY KEY (id);


--
-- Name: cca_ride_settings cca_ride_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_ride_settings
    ADD CONSTRAINT cca_ride_settings_pkey PRIMARY KEY (id);


--
-- Name: client_billing_contacts client_billing_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_billing_contacts
    ADD CONSTRAINT client_billing_contacts_pkey PRIMARY KEY (id);


--
-- Name: client_bookable_vehicle_types client_bookable_vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_bookable_vehicle_types
    ADD CONSTRAINT client_bookable_vehicle_types_pkey PRIMARY KEY (id);


--
-- Name: client_end_customers client_end_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_end_customers
    ADD CONSTRAINT client_end_customers_pkey PRIMARY KEY (id);


--
-- Name: client_invoice_line_runs client_invoice_line_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_line_runs
    ADD CONSTRAINT client_invoice_line_runs_pkey PRIMARY KEY (id);


--
-- Name: client_invoice_lines client_invoice_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_lines
    ADD CONSTRAINT client_invoice_lines_pkey PRIMARY KEY (id);


--
-- Name: client_invoice_payments client_invoice_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_payments
    ADD CONSTRAINT client_invoice_payments_pkey PRIMARY KEY (id);


--
-- Name: client_invoice_sends client_invoice_sends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_sends
    ADD CONSTRAINT client_invoice_sends_pkey PRIMARY KEY (id);


--
-- Name: client_invoices client_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT client_invoices_pkey PRIMARY KEY (id);


--
-- Name: client_pickup_points client_pickup_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_pickup_points
    ADD CONSTRAINT client_pickup_points_pkey PRIMARY KEY (id);


--
-- Name: client_sites client_sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_sites
    ADD CONSTRAINT client_sites_pkey PRIMARY KEY (id);


--
-- Name: client_user_sites client_user_sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_user_sites
    ADD CONSTRAINT client_user_sites_pkey PRIMARY KEY (id);


--
-- Name: client_users client_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_users
    ADD CONSTRAINT client_users_pkey PRIMARY KEY (id);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_country_requests company_country_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_country_requests
    ADD CONSTRAINT company_country_requests_pkey PRIMARY KEY (id);


--
-- Name: company_lead_domains company_lead_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_lead_domains
    ADD CONSTRAINT company_lead_domains_pkey PRIMARY KEY (id);


--
-- Name: company_leads company_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_leads
    ADD CONSTRAINT company_leads_pkey PRIMARY KEY (id);


--
-- Name: company_sequences company_sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_sequences
    ADD CONSTRAINT company_sequences_pkey PRIMARY KEY (id);


--
-- Name: dashboard_layouts dashboard_layouts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_layouts
    ADD CONSTRAINT dashboard_layouts_pkey PRIMARY KEY (id);


--
-- Name: disabled_vehicle_types disabled_vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_vehicle_types
    ADD CONSTRAINT disabled_vehicle_types_pkey PRIMARY KEY (id);


--
-- Name: discover_advertisers discover_advertisers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discover_advertisers
    ADD CONSTRAINT discover_advertisers_pkey PRIMARY KEY (id);


--
-- Name: discover_placements discover_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discover_placements
    ADD CONSTRAINT discover_placements_pkey PRIMARY KEY (id);


--
-- Name: document_reads document_reads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_reads
    ADD CONSTRAINT document_reads_pkey PRIMARY KEY (id);


--
-- Name: driver_app_sessions driver_app_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_app_sessions
    ADD CONSTRAINT driver_app_sessions_pkey PRIMARY KEY (id);


--
-- Name: driver_invites driver_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_invites
    ADD CONSTRAINT driver_invites_pkey PRIMARY KEY (id);


--
-- Name: driver_kyc_profiles driver_kyc_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_kyc_profiles
    ADD CONSTRAINT driver_kyc_profiles_pkey PRIMARY KEY (id);


--
-- Name: driver_pay_month_lines driver_pay_month_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_month_lines
    ADD CONSTRAINT driver_pay_month_lines_pkey PRIMARY KEY (id);


--
-- Name: driver_pay_month_runs driver_pay_month_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_month_runs
    ADD CONSTRAINT driver_pay_month_runs_pkey PRIMARY KEY (id);


--
-- Name: driver_pay_months driver_pay_months_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_months
    ADD CONSTRAINT driver_pay_months_pkey PRIMARY KEY (id);


--
-- Name: driver_pay_schemes driver_pay_schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_schemes
    ADD CONSTRAINT driver_pay_schemes_pkey PRIMARY KEY (id);


--
-- Name: driver_point_allocations driver_point_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_allocations
    ADD CONSTRAINT driver_point_allocations_pkey PRIMARY KEY (id);


--
-- Name: driver_point_deductions driver_point_deductions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_deductions
    ADD CONSTRAINT driver_point_deductions_pkey PRIMARY KEY (id);


--
-- Name: driver_point_lots driver_point_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_lots
    ADD CONSTRAINT driver_point_lots_pkey PRIMARY KEY (id);


--
-- Name: driver_vehicle_types driver_vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_vehicle_types
    ADD CONSTRAINT driver_vehicle_types_pkey PRIMARY KEY (id);


--
-- Name: drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- Name: external_vehicle_share_links external_vehicle_share_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_share_links
    ADD CONSTRAINT external_vehicle_share_links_pkey PRIMARY KEY (id);


--
-- Name: external_vehicle_submissions external_vehicle_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_submissions
    ADD CONSTRAINT external_vehicle_submissions_pkey PRIMARY KEY (id);


--
-- Name: families families_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.families
    ADD CONSTRAINT families_pkey PRIMARY KEY (id);


--
-- Name: family_guardians family_guardians_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_guardians
    ADD CONSTRAINT family_guardians_pkey PRIMARY KEY (id);


--
-- Name: family_riders family_riders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_riders
    ADD CONSTRAINT family_riders_pkey PRIMARY KEY (id);


--
-- Name: fare_adjustments fare_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_adjustments
    ADD CONSTRAINT fare_adjustments_pkey PRIMARY KEY (id);


--
-- Name: fare_bus_rates fare_bus_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_bus_rates
    ADD CONSTRAINT fare_bus_rates_pkey PRIMARY KEY (id);


--
-- Name: fare_size_columns fare_size_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_size_columns
    ADD CONSTRAINT fare_size_columns_pkey PRIMARY KEY (id);


--
-- Name: fare_surcharges fare_surcharges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_surcharges
    ADD CONSTRAINT fare_surcharges_pkey PRIMARY KEY (id);


--
-- Name: fare_tables fare_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tables
    ADD CONSTRAINT fare_tables_pkey PRIMARY KEY (id);


--
-- Name: fare_tier_sizes fare_tier_sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tier_sizes
    ADD CONSTRAINT fare_tier_sizes_pkey PRIMARY KEY (id);


--
-- Name: fare_tiers fare_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tiers
    ADD CONSTRAINT fare_tiers_pkey PRIMARY KEY (id);


--
-- Name: feasibility_bus_prices feasibility_bus_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_bus_prices
    ADD CONSTRAINT feasibility_bus_prices_pkey PRIMARY KEY (id);


--
-- Name: feasibility_fare_tiers feasibility_fare_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_fare_tiers
    ADD CONSTRAINT feasibility_fare_tiers_pkey PRIMARY KEY (id);


--
-- Name: feasibility_rows feasibility_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_rows
    ADD CONSTRAINT feasibility_rows_pkey PRIMARY KEY (id);


--
-- Name: feasibility_scenarios feasibility_scenarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_scenarios
    ADD CONSTRAINT feasibility_scenarios_pkey PRIMARY KEY (id);


--
-- Name: feasibility_studies feasibility_studies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_studies
    ADD CONSTRAINT feasibility_studies_pkey PRIMARY KEY (id);


--
-- Name: finance_approvers finance_approvers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_approvers
    ADD CONSTRAINT finance_approvers_pkey PRIMARY KEY (id);


--
-- Name: finance_settings finance_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_settings
    ADD CONSTRAINT finance_settings_pkey PRIMARY KEY (id);


--
-- Name: fuel_alerts fuel_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_alerts
    ADD CONSTRAINT fuel_alerts_pkey PRIMARY KEY (id);


--
-- Name: fuel_companies fuel_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_companies
    ADD CONSTRAINT fuel_companies_pkey PRIMARY KEY (id);


--
-- Name: fuel_entries fuel_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_entries
    ADD CONSTRAINT fuel_entries_pkey PRIMARY KEY (id);


--
-- Name: maintenance_invoices maintenance_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_invoices
    ADD CONSTRAINT maintenance_invoices_pkey PRIMARY KEY (id);


--
-- Name: maintenance_lines maintenance_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_lines
    ADD CONSTRAINT maintenance_lines_pkey PRIMARY KEY (id);


--
-- Name: maintenance_visits maintenance_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_visits
    ADD CONSTRAINT maintenance_visits_pkey PRIMARY KEY (id);


--
-- Name: message_terms message_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_terms
    ADD CONSTRAINT message_terms_pkey PRIMARY KEY (id);


--
-- Name: notice_deliveries notice_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_deliveries
    ADD CONSTRAINT notice_deliveries_pkey PRIMARY KEY (id);


--
-- Name: notice_routes notice_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_routes
    ADD CONSTRAINT notice_routes_pkey PRIMARY KEY (id);


--
-- Name: notice_runs notice_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_runs
    ADD CONSTRAINT notice_runs_pkey PRIMARY KEY (id);


--
-- Name: notice_templates notice_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_templates
    ADD CONSTRAINT notice_templates_pkey PRIMARY KEY (id);


--
-- Name: notices notices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT notices_pkey PRIMARY KEY (id);


--
-- Name: notification_emails notification_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_emails
    ADD CONSTRAINT notification_emails_pkey PRIMARY KEY (id);


--
-- Name: occurrence_correction_logs occurrence_correction_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_logs
    ADD CONSTRAINT occurrence_correction_logs_pkey PRIMARY KEY (id);


--
-- Name: occurrence_correction_stops occurrence_correction_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_stops
    ADD CONSTRAINT occurrence_correction_stops_pkey PRIMARY KEY (id);


--
-- Name: occurrence_corrections occurrence_corrections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_corrections
    ADD CONSTRAINT occurrence_corrections_pkey PRIMARY KEY (id);


--
-- Name: occurrence_driver_reports occurrence_driver_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_driver_reports
    ADD CONSTRAINT occurrence_driver_reports_pkey PRIMARY KEY (id);


--
-- Name: occurrence_notes occurrence_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_notes
    ADD CONSTRAINT occurrence_notes_pkey PRIMARY KEY (id);


--
-- Name: occurrence_positions occurrence_positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions
    ADD CONSTRAINT occurrence_positions_pkey PRIMARY KEY (id, occurrence_date);


--
-- Name: occurrence_positions_y2026m09 occurrence_positions_y2026m09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions_y2026m09
    ADD CONSTRAINT occurrence_positions_y2026m09_pkey PRIMARY KEY (id, occurrence_date);


--
-- Name: occurrence_positions_y2026m10 occurrence_positions_y2026m10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions_y2026m10
    ADD CONSTRAINT occurrence_positions_y2026m10_pkey PRIMARY KEY (id, occurrence_date);


--
-- Name: occurrence_positions_y2026m11 occurrence_positions_y2026m11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions_y2026m11
    ADD CONSTRAINT occurrence_positions_y2026m11_pkey PRIMARY KEY (id, occurrence_date);


--
-- Name: occurrence_positions_y2026m12 occurrence_positions_y2026m12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions_y2026m12
    ADD CONSTRAINT occurrence_positions_y2026m12_pkey PRIMARY KEY (id, occurrence_date);


--
-- Name: occurrence_positions_y2027m01 occurrence_positions_y2027m01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions_y2027m01
    ADD CONSTRAINT occurrence_positions_y2027m01_pkey PRIMARY KEY (id, occurrence_date);


--
-- Name: occurrence_positions_y2027m02 occurrence_positions_y2027m02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions_y2027m02
    ADD CONSTRAINT occurrence_positions_y2027m02_pkey PRIMARY KEY (id, occurrence_date);


--
-- Name: occurrence_positions_y2027m03 occurrence_positions_y2027m03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_positions_y2027m03
    ADD CONSTRAINT occurrence_positions_y2027m03_pkey PRIMARY KEY (id, occurrence_date);


--
-- Name: occurrence_report_photos occurrence_report_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_report_photos
    ADD CONSTRAINT occurrence_report_photos_pkey PRIMARY KEY (id);


--
-- Name: occurrence_stop_events occurrence_stop_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_stop_events
    ADD CONSTRAINT occurrence_stop_events_pkey PRIMARY KEY (id);


--
-- Name: occurrence_trip_summaries occurrence_trip_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_trip_summaries
    ADD CONSTRAINT occurrence_trip_summaries_pkey PRIMARY KEY (id);


--
-- Name: operator_cost_overrides operator_cost_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_cost_overrides
    ADD CONSTRAINT operator_cost_overrides_pkey PRIMARY KEY (id);


--
-- Name: operator_drivers operator_drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers
    ADD CONSTRAINT operator_drivers_pkey PRIMARY KEY (id);


--
-- Name: operator_pay_batch_lines operator_pay_batch_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batch_lines
    ADD CONSTRAINT operator_pay_batch_lines_pkey PRIMARY KEY (id);


--
-- Name: operator_pay_batch_operators operator_pay_batch_operators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batch_operators
    ADD CONSTRAINT operator_pay_batch_operators_pkey PRIMARY KEY (id);


--
-- Name: operator_pay_batches operator_pay_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batches
    ADD CONSTRAINT operator_pay_batches_pkey PRIMARY KEY (id);


--
-- Name: operator_pay_items operator_pay_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_items
    ADD CONSTRAINT operator_pay_items_pkey PRIMARY KEY (id);


--
-- Name: operator_pay_payments operator_pay_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_payments
    ADD CONSTRAINT operator_pay_payments_pkey PRIMARY KEY (id);


--
-- Name: operators operators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators
    ADD CONSTRAINT operators_pkey PRIMARY KEY (id);


--
-- Name: ops_alerts ops_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ops_alerts
    ADD CONSTRAINT ops_alerts_pkey PRIMARY KEY (id);


--
-- Name: pay_bonus_drivers pay_bonus_drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_drivers
    ADD CONSTRAINT pay_bonus_drivers_pkey PRIMARY KEY (id);


--
-- Name: pay_bonus_excluded_periods pay_bonus_excluded_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_excluded_periods
    ADD CONSTRAINT pay_bonus_excluded_periods_pkey PRIMARY KEY (id);


--
-- Name: pay_bonus_payments pay_bonus_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_payments
    ADD CONSTRAINT pay_bonus_payments_pkey PRIMARY KEY (id);


--
-- Name: pay_bonus_schemes pay_bonus_schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_schemes
    ADD CONSTRAINT pay_bonus_schemes_pkey PRIMARY KEY (id);


--
-- Name: pay_bonus_tiers pay_bonus_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_tiers
    ADD CONSTRAINT pay_bonus_tiers_pkey PRIMARY KEY (id);


--
-- Name: pay_bonuses pay_bonuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonuses
    ADD CONSTRAINT pay_bonuses_pkey PRIMARY KEY (id);


--
-- Name: pay_rate_period_ranges pay_rate_period_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_period_ranges
    ADD CONSTRAINT pay_rate_period_ranges_pkey PRIMARY KEY (id);


--
-- Name: pay_rate_periods pay_rate_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_periods
    ADD CONSTRAINT pay_rate_periods_pkey PRIMARY KEY (id);


--
-- Name: pay_rate_plan_vehicle_types pay_rate_plan_vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_plan_vehicle_types
    ADD CONSTRAINT pay_rate_plan_vehicle_types_pkey PRIMARY KEY (id);


--
-- Name: pay_rate_plans pay_rate_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_plans
    ADD CONSTRAINT pay_rate_plans_pkey PRIMARY KEY (id);


--
-- Name: pay_rates pay_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rates
    ADD CONSTRAINT pay_rates_pkey PRIMARY KEY (id);


--
-- Name: pay_rewards pay_rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rewards
    ADD CONSTRAINT pay_rewards_pkey PRIMARY KEY (id);


--
-- Name: pay_scheme_route_bands pay_scheme_route_bands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_route_bands
    ADD CONSTRAINT pay_scheme_route_bands_pkey PRIMARY KEY (id);


--
-- Name: pay_scheme_target_tiers pay_scheme_target_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_target_tiers
    ADD CONSTRAINT pay_scheme_target_tiers_pkey PRIMARY KEY (id);


--
-- Name: pay_scheme_volume_tiers pay_scheme_volume_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_volume_tiers
    ADD CONSTRAINT pay_scheme_volume_tiers_pkey PRIMARY KEY (id);


--
-- Name: pay_schemes pay_schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_schemes
    ADD CONSTRAINT pay_schemes_pkey PRIMARY KEY (id);


--
-- Name: pay_simulator_templates pay_simulator_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_simulator_templates
    ADD CONSTRAINT pay_simulator_templates_pkey PRIMARY KEY (id);


--
-- Name: pickup_points pickup_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pickup_points
    ADD CONSTRAINT pickup_points_pkey PRIMARY KEY (id);


--
-- Name: plan_comments plan_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_comments
    ADD CONSTRAINT plan_comments_pkey PRIMARY KEY (id);


--
-- Name: policy_reminders policy_reminders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_reminders
    ADD CONSTRAINT policy_reminders_pkey PRIMARY KEY (id);


--
-- Name: portal_accounts portal_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_accounts
    ADD CONSTRAINT portal_accounts_pkey PRIMARY KEY (id);


--
-- Name: portal_jwts portal_jwts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_jwts
    ADD CONSTRAINT portal_jwts_pkey PRIMARY KEY (id);


--
-- Name: portal_sign_in_codes portal_sign_in_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_sign_in_codes
    ADD CONSTRAINT portal_sign_in_codes_pkey PRIMARY KEY (id);


--
-- Name: postal_geocodes postal_geocodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postal_geocodes
    ADD CONSTRAINT postal_geocodes_pkey PRIMARY KEY (id);


--
-- Name: public_holidays public_holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_holidays
    ADD CONSTRAINT public_holidays_pkey PRIMARY KEY (id);


--
-- Name: rate_card_amounts rate_card_amounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_amounts
    ADD CONSTRAINT rate_card_amounts_pkey PRIMARY KEY (id);


--
-- Name: rate_card_distance_bands rate_card_distance_bands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_distance_bands
    ADD CONSTRAINT rate_card_distance_bands_pkey PRIMARY KEY (id);


--
-- Name: rate_card_periods rate_card_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_periods
    ADD CONSTRAINT rate_card_periods_pkey PRIMARY KEY (id);


--
-- Name: rate_card_ranges rate_card_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_ranges
    ADD CONSTRAINT rate_card_ranges_pkey PRIMARY KEY (id);


--
-- Name: rate_card_rates rate_card_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_rates
    ADD CONSTRAINT rate_card_rates_pkey PRIMARY KEY (id);


--
-- Name: rate_card_vehicle_types rate_card_vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_vehicle_types
    ADD CONSTRAINT rate_card_vehicle_types_pkey PRIMARY KEY (id);


--
-- Name: rate_cards rate_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_cards
    ADD CONSTRAINT rate_cards_pkey PRIMARY KEY (id);


--
-- Name: registration_messages registration_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registration_messages
    ADD CONSTRAINT registration_messages_pkey PRIMARY KEY (id);


--
-- Name: replacement_notifications replacement_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_notifications
    ADD CONSTRAINT replacement_notifications_pkey PRIMARY KEY (id);


--
-- Name: replacements replacements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT replacements_pkey PRIMARY KEY (id);


--
-- Name: rider_assignments rider_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT rider_assignments_pkey PRIMARY KEY (id);


--
-- Name: rider_datasets rider_datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_datasets
    ADD CONSTRAINT rider_datasets_pkey PRIMARY KEY (id);


--
-- Name: rider_point_links rider_point_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_point_links
    ADD CONSTRAINT rider_point_links_pkey PRIMARY KEY (id);


--
-- Name: route_charges route_charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_charges
    ADD CONSTRAINT route_charges_pkey PRIMARY KEY (id);


--
-- Name: route_list_version_stops route_list_version_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_version_stops
    ADD CONSTRAINT route_list_version_stops_pkey PRIMARY KEY (id);


--
-- Name: route_list_version_students route_list_version_students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_version_students
    ADD CONSTRAINT route_list_version_students_pkey PRIMARY KEY (id);


--
-- Name: route_list_versions route_list_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_versions
    ADD CONSTRAINT route_list_versions_pkey PRIMARY KEY (id);


--
-- Name: routing_runs routing_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_runs
    ADD CONSTRAINT routing_runs_pkey PRIMARY KEY (id);


--
-- Name: routing_settings routing_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_settings
    ADD CONSTRAINT routing_settings_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: school_attendant_policies school_attendant_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_attendant_policies
    ADD CONSTRAINT school_attendant_policies_pkey PRIMARY KEY (id);


--
-- Name: school_bill_lines school_bill_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bill_lines
    ADD CONSTRAINT school_bill_lines_pkey PRIMARY KEY (id);


--
-- Name: school_bills school_bills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT school_bills_pkey PRIMARY KEY (id);


--
-- Name: school_bus_size_rates school_bus_size_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bus_size_rates
    ADD CONSTRAINT school_bus_size_rates_pkey PRIMARY KEY (id);


--
-- Name: school_holidays school_holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_holidays
    ADD CONSTRAINT school_holidays_pkey PRIMARY KEY (id);


--
-- Name: school_levels school_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_levels
    ADD CONSTRAINT school_levels_pkey PRIMARY KEY (id);


--
-- Name: school_operator_pays school_operator_pays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_operator_pays
    ADD CONSTRAINT school_operator_pays_pkey PRIMARY KEY (id);


--
-- Name: school_payment_methods school_payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_payment_methods
    ADD CONSTRAINT school_payment_methods_pkey PRIMARY KEY (id);


--
-- Name: school_plan_changes school_plan_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plan_changes
    ADD CONSTRAINT school_plan_changes_pkey PRIMARY KEY (id);


--
-- Name: school_plans school_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plans
    ADD CONSTRAINT school_plans_pkey PRIMARY KEY (id);


--
-- Name: school_policy_versions school_policy_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_policy_versions
    ADD CONSTRAINT school_policy_versions_pkey PRIMARY KEY (id);


--
-- Name: school_registrations school_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_registrations
    ADD CONSTRAINT school_registrations_pkey PRIMARY KEY (id);


--
-- Name: school_riders school_riders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_riders
    ADD CONSTRAINT school_riders_pkey PRIMARY KEY (id);


--
-- Name: school_route_labels school_route_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_labels
    ADD CONSTRAINT school_route_labels_pkey PRIMARY KEY (id);


--
-- Name: school_route_prices school_route_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_prices
    ADD CONSTRAINT school_route_prices_pkey PRIMARY KEY (id);


--
-- Name: school_route_replacements school_route_replacements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_replacements
    ADD CONSTRAINT school_route_replacements_pkey PRIMARY KEY (id);


--
-- Name: school_route_riders school_route_riders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_riders
    ADD CONSTRAINT school_route_riders_pkey PRIMARY KEY (id);


--
-- Name: school_route_stops school_route_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_stops
    ADD CONSTRAINT school_route_stops_pkey PRIMARY KEY (id);


--
-- Name: school_route_vehicle_changes school_route_vehicle_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_vehicle_changes
    ADD CONSTRAINT school_route_vehicle_changes_pkey PRIMARY KEY (id);


--
-- Name: school_routes school_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_routes
    ADD CONSTRAINT school_routes_pkey PRIMARY KEY (id);


--
-- Name: school_special_days school_special_days_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_special_days
    ADD CONSTRAINT school_special_days_pkey PRIMARY KEY (id);


--
-- Name: school_stops school_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_stops
    ADD CONSTRAINT school_stops_pkey PRIMARY KEY (id);


--
-- Name: schools schools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_pkey PRIMARY KEY (id);


--
-- Name: setup_locks setup_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setup_locks
    ADD CONSTRAINT setup_locks_pkey PRIMARY KEY (id);


--
-- Name: stop_photo_requests stop_photo_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_requests
    ADD CONSTRAINT stop_photo_requests_pkey PRIMARY KEY (id);


--
-- Name: stop_photo_submissions stop_photo_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_submissions
    ADD CONSTRAINT stop_photo_submissions_pkey PRIMARY KEY (id);


--
-- Name: stop_points stop_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_points
    ADD CONSTRAINT stop_points_pkey PRIMARY KEY (id);


--
-- Name: stops stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stops
    ADD CONSTRAINT stops_pkey PRIMARY KEY (id);


--
-- Name: student_attendances student_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_pkey PRIMARY KEY (id);


--
-- Name: tracking_devices tracking_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_devices
    ADD CONSTRAINT tracking_devices_pkey PRIMARY KEY (id);


--
-- Name: tracking_links tracking_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_links
    ADD CONSTRAINT tracking_links_pkey PRIMARY KEY (id);


--
-- Name: trip_assignment_slots trip_assignment_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignment_slots
    ADD CONSTRAINT trip_assignment_slots_pkey PRIMARY KEY (id);


--
-- Name: trip_assignments trip_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT trip_assignments_pkey PRIMARY KEY (id);


--
-- Name: trip_attachments trip_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_attachments
    ADD CONSTRAINT trip_attachments_pkey PRIMARY KEY (id);


--
-- Name: trip_occurrences trip_occurrences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_pkey PRIMARY KEY (id, date);


--
-- Name: trip_occurrences_y2026m09 trip_occurrences_y2026m09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences_y2026m09
    ADD CONSTRAINT trip_occurrences_y2026m09_pkey PRIMARY KEY (id, date);


--
-- Name: trip_occurrences_y2026m10 trip_occurrences_y2026m10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences_y2026m10
    ADD CONSTRAINT trip_occurrences_y2026m10_pkey PRIMARY KEY (id, date);


--
-- Name: trip_occurrences_y2026m11 trip_occurrences_y2026m11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences_y2026m11
    ADD CONSTRAINT trip_occurrences_y2026m11_pkey PRIMARY KEY (id, date);


--
-- Name: trip_occurrences_y2026m12 trip_occurrences_y2026m12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences_y2026m12
    ADD CONSTRAINT trip_occurrences_y2026m12_pkey PRIMARY KEY (id, date);


--
-- Name: trip_occurrences_y2027m01 trip_occurrences_y2027m01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences_y2027m01
    ADD CONSTRAINT trip_occurrences_y2027m01_pkey PRIMARY KEY (id, date);


--
-- Name: trip_occurrences_y2027m02 trip_occurrences_y2027m02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences_y2027m02
    ADD CONSTRAINT trip_occurrences_y2027m02_pkey PRIMARY KEY (id, date);


--
-- Name: trip_occurrences_y2027m03 trip_occurrences_y2027m03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_occurrences_y2027m03
    ADD CONSTRAINT trip_occurrences_y2027m03_pkey PRIMARY KEY (id, date);


--
-- Name: trip_price_cells trip_price_cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_price_cells
    ADD CONSTRAINT trip_price_cells_pkey PRIMARY KEY (id);


--
-- Name: trip_route_vias trip_route_vias_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_route_vias
    ADD CONSTRAINT trip_route_vias_order UNIQUE (trip_id, direction, from_position, "position") DEFERRABLE INITIALLY DEFERRED;


--
-- Name: trip_route_vias trip_route_vias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_route_vias
    ADD CONSTRAINT trip_route_vias_pkey PRIMARY KEY (id);


--
-- Name: trip_run_groups trip_run_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_groups
    ADD CONSTRAINT trip_run_groups_pkey PRIMARY KEY (id);


--
-- Name: trip_run_slots trip_run_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_slots
    ADD CONSTRAINT trip_run_slots_pkey PRIMARY KEY (id);


--
-- Name: trip_run_times trip_run_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_times
    ADD CONSTRAINT trip_run_times_pkey PRIMARY KEY (id);


--
-- Name: trip_runs trip_runs_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_runs
    ADD CONSTRAINT trip_runs_order UNIQUE (trip_id, direction, "position") DEFERRABLE INITIALLY DEFERRED;


--
-- Name: trip_runs trip_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_runs
    ADD CONSTRAINT trip_runs_pkey PRIMARY KEY (id);


--
-- Name: trip_standby_photos trip_standby_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_standby_photos
    ADD CONSTRAINT trip_standby_photos_pkey PRIMARY KEY (id);


--
-- Name: trip_standbys trip_standbys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_standbys
    ADD CONSTRAINT trip_standbys_pkey PRIMARY KEY (id);


--
-- Name: trip_stop_photos trip_stop_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_photos
    ADD CONSTRAINT trip_stop_photos_pkey PRIMARY KEY (id);


--
-- Name: trip_stop_students trip_stop_students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_students
    ADD CONSTRAINT trip_stop_students_pkey PRIMARY KEY (id);


--
-- Name: trip_stops trip_stops_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT trip_stops_order UNIQUE (trip_id, direction, "position") DEFERRABLE INITIALLY DEFERRED;


--
-- Name: trip_stops trip_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT trip_stops_pkey PRIMARY KEY (id);


--
-- Name: trip_time_changes trip_time_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_time_changes
    ADD CONSTRAINT trip_time_changes_pkey PRIMARY KEY (id);


--
-- Name: trip_vehicle_requirements trip_vehicle_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_requirements
    ADD CONSTRAINT trip_vehicle_requirements_pkey PRIMARY KEY (id);


--
-- Name: trip_vehicle_slots trip_vehicle_slots_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_slots
    ADD CONSTRAINT trip_vehicle_slots_order UNIQUE (trip_id, slot_no) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: trip_vehicle_slots trip_vehicle_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_slots
    ADD CONSTRAINT trip_vehicle_slots_pkey PRIMARY KEY (id);


--
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (id);


--
-- Name: ura_subzones ura_subzones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ura_subzones
    ADD CONSTRAINT ura_subzones_pkey PRIMARY KEY (id);


--
-- Name: user_notification_preferences user_notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notification_preferences
    ADD CONSTRAINT user_notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_schools user_schools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_schools
    ADD CONSTRAINT user_schools_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicle_cost_spike_acks vehicle_cost_spike_acks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_cost_spike_acks
    ADD CONSTRAINT vehicle_cost_spike_acks_pkey PRIMARY KEY (id);


--
-- Name: vehicle_driver_schedules vehicle_driver_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT vehicle_driver_schedules_pkey PRIMARY KEY (id);


--
-- Name: vehicle_finance_entries vehicle_finance_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_finance_entries
    ADD CONSTRAINT vehicle_finance_entries_pkey PRIMARY KEY (id);


--
-- Name: vehicle_financials vehicle_financials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_financials
    ADD CONSTRAINT vehicle_financials_pkey PRIMARY KEY (id);


--
-- Name: vehicle_insurance_documents vehicle_insurance_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_insurance_documents
    ADD CONSTRAINT vehicle_insurance_documents_pkey PRIMARY KEY (id);


--
-- Name: vehicle_insurance_policies vehicle_insurance_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_insurance_policies
    ADD CONSTRAINT vehicle_insurance_policies_pkey PRIMARY KEY (id);


--
-- Name: vehicle_live_positions vehicle_live_positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_live_positions
    ADD CONSTRAINT vehicle_live_positions_pkey PRIMARY KEY (id);


--
-- Name: vehicle_loan_payments vehicle_loan_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_loan_payments
    ADD CONSTRAINT vehicle_loan_payments_pkey PRIMARY KEY (id);


--
-- Name: vehicle_log_cards vehicle_log_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_log_cards
    ADD CONSTRAINT vehicle_log_cards_pkey PRIMARY KEY (id);


--
-- Name: vehicle_teams vehicle_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_teams
    ADD CONSTRAINT vehicle_teams_pkey PRIMARY KEY (id);


--
-- Name: vehicle_type_requests vehicle_type_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_type_requests
    ADD CONSTRAINT vehicle_type_requests_pkey PRIMARY KEY (id);


--
-- Name: vehicle_types vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_types
    ADD CONSTRAINT vehicle_types_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: workshops workshops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workshops
    ADD CONSTRAINT workshops_pkey PRIMARY KEY (id);


--
-- Name: associated_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX associated_index ON public.audits USING btree (associated_type, associated_id);


--
-- Name: auditable_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditable_index ON public.audits USING btree (auditable_type, auditable_id, version);


--
-- Name: idx_on_booking_trip_id_leg_position_9ccf998ef7; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_booking_trip_id_leg_position_9ccf998ef7 ON public.booking_trip_points USING btree (booking_trip_id, leg, "position");


--
-- Name: idx_on_booking_trip_id_vehicle_type_id_ca7b84be82; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_booking_trip_id_vehicle_type_id_ca7b84be82 ON public.booking_trip_vehicles USING btree (booking_trip_id, vehicle_type_id);


--
-- Name: idx_on_client_id_vehicle_type_id_9602a14b65; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_client_id_vehicle_type_id_9602a14b65 ON public.client_bookable_vehicle_types USING btree (client_id, vehicle_type_id);


--
-- Name: idx_on_company_id_status_created_at_f335c61b86; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_company_id_status_created_at_f335c61b86 ON public.external_vehicle_submissions USING btree (company_id, status, created_at);


--
-- Name: idx_on_company_id_vocational_licence_expires_on_68d32c5ee3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_company_id_vocational_licence_expires_on_68d32c5ee3 ON public.driver_kyc_profiles USING btree (company_id, vocational_licence_expires_on);


--
-- Name: idx_on_feasibility_study_id_bus_type_f4b637ec38; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_feasibility_study_id_bus_type_f4b637ec38 ON public.feasibility_bus_prices USING btree (feasibility_study_id, bus_type);


--
-- Name: idx_on_feasibility_study_id_position_e835660dba; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_feasibility_study_id_position_e835660dba ON public.feasibility_fare_tiers USING btree (feasibility_study_id, "position");


--
-- Name: idx_on_occurrence_correction_id_position_806b25c265; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_occurrence_correction_id_position_806b25c265 ON public.occurrence_correction_stops USING btree (occurrence_correction_id, "position");


--
-- Name: idx_on_occurrence_id_occurrence_date_42a0837d73; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_occurrence_id_occurrence_date_42a0837d73 ON public.occurrence_driver_reports USING btree (occurrence_id, occurrence_date);


--
-- Name: idx_on_occurrence_id_occurrence_date_777d975dcf; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_occurrence_id_occurrence_date_777d975dcf ON public.occurrence_corrections USING btree (occurrence_id, occurrence_date);


--
-- Name: idx_on_occurrence_id_occurrence_date_817e8d9e46; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_occurrence_id_occurrence_date_817e8d9e46 ON public.occurrence_trip_summaries USING btree (occurrence_id, occurrence_date);


--
-- Name: idx_on_occurrence_id_occurrence_date_c0b0455ad1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_occurrence_id_occurrence_date_c0b0455ad1 ON public.driver_pay_month_runs USING btree (occurrence_id, occurrence_date);


--
-- Name: idx_on_occurrence_id_occurrence_date_f3ece8f775; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_occurrence_id_occurrence_date_f3ece8f775 ON public.operator_cost_overrides USING btree (occurrence_id, occurrence_date);


--
-- Name: idx_on_occurrence_id_occurrence_date_position_02f6e5902d; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_occurrence_id_occurrence_date_position_02f6e5902d ON public.occurrence_stop_events USING btree (occurrence_id, occurrence_date, "position");


--
-- Name: idx_on_operator_driver_id_signed_in_at_078880f84a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_operator_driver_id_signed_in_at_078880f84a ON public.driver_app_sessions USING btree (operator_driver_id, signed_in_at) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: idx_on_operator_pay_batch_operator_id_f3447135c0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_operator_pay_batch_operator_id_f3447135c0 ON public.operator_pay_batch_lines USING btree (operator_pay_batch_operator_id);


--
-- Name: idx_on_rate_card_id_vehicle_type_id_a715fca998; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_rate_card_id_vehicle_type_id_a715fca998 ON public.rate_card_vehicle_types USING btree (rate_card_id, vehicle_type_id);


--
-- Name: idx_on_rate_card_period_id_vehicle_type_id_62c4167068; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_rate_card_period_id_vehicle_type_id_62c4167068 ON public.rate_card_rates USING btree (rate_card_period_id, vehicle_type_id);


--
-- Name: idx_on_route_list_version_stop_id_a1ccadebd0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_route_list_version_stop_id_a1ccadebd0 ON public.route_list_version_students USING btree (route_list_version_stop_id);


--
-- Name: idx_on_school_policy_version_id_position_dcb28cb4b5; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_school_policy_version_id_position_dcb28cb4b5 ON public.policy_reminders USING btree (school_policy_version_id, "position");


--
-- Name: idx_on_school_route_id_effective_from_56e66aaed7; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_school_route_id_effective_from_56e66aaed7 ON public.school_route_prices USING btree (school_route_id, effective_from);


--
-- Name: idx_on_vehicle_insurance_policy_id_83c63fa225; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_vehicle_insurance_policy_id_83c63fa225 ON public.vehicle_insurance_documents USING btree (vehicle_insurance_policy_id);


--
-- Name: index_academic_terms_on_academic_year_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_academic_terms_on_academic_year_id_and_position ON public.academic_terms USING btree (academic_year_id, "position");


--
-- Name: index_academic_years_on_school_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_academic_years_on_school_id_and_key ON public.academic_years USING btree (school_id, key);


--
-- Name: index_academic_years_on_school_id_and_starts_on_and_ends_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_academic_years_on_school_id_and_starts_on_and_ends_on ON public.academic_years USING btree (school_id, starts_on, ends_on);


--
-- Name: index_allowlisted_jwts_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allowlisted_jwts_on_company_id ON public.allowlisted_jwts USING btree (company_id);


--
-- Name: index_allowlisted_jwts_on_exp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allowlisted_jwts_on_exp ON public.allowlisted_jwts USING btree (exp);


--
-- Name: index_allowlisted_jwts_on_jti; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_allowlisted_jwts_on_jti ON public.allowlisted_jwts USING btree (jti);


--
-- Name: index_allowlisted_jwts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allowlisted_jwts_on_user_id ON public.allowlisted_jwts USING btree (user_id);


--
-- Name: index_attendants_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attendants_on_company_id ON public.attendants USING btree (company_id);


--
-- Name: index_attendants_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attendants_on_discarded_at ON public.attendants USING btree (discarded_at);


--
-- Name: index_audits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_created_at ON public.audits USING btree (created_at);


--
-- Name: index_audits_on_request_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_request_uuid ON public.audits USING btree (request_uuid);


--
-- Name: index_bank_branches_on_bank_id_and_account_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bank_branches_on_bank_id_and_account_prefix ON public.bank_branches USING btree (bank_id, account_prefix) WHERE (account_prefix IS NOT NULL);


--
-- Name: index_bank_branches_on_bank_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_branches_on_bank_id_and_code ON public.bank_branches USING btree (bank_id, code);


--
-- Name: index_banks_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_banks_on_code ON public.banks USING btree (code);


--
-- Name: index_banks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_banks_on_key ON public.banks USING btree (key);


--
-- Name: index_booking_attachments_on_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_attachments_on_booking_id ON public.booking_attachments USING btree (booking_id);


--
-- Name: index_booking_attachments_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_attachments_on_company_id ON public.booking_attachments USING btree (company_id);


--
-- Name: index_booking_attachments_on_uploaded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_attachments_on_uploaded_by_id ON public.booking_attachments USING btree (uploaded_by_id);


--
-- Name: index_booking_cancel_requests_on_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_cancel_requests_on_booking_id ON public.booking_cancel_requests USING btree (booking_id);


--
-- Name: index_booking_cancel_requests_on_booking_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_cancel_requests_on_booking_trip_id ON public.booking_cancel_requests USING btree (booking_trip_id);


--
-- Name: index_booking_cancel_requests_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_cancel_requests_on_company_id ON public.booking_cancel_requests USING btree (company_id);


--
-- Name: index_booking_cancel_requests_on_company_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_cancel_requests_on_company_id_and_status ON public.booking_cancel_requests USING btree (company_id, status);


--
-- Name: index_booking_cancel_requests_on_resolved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_cancel_requests_on_resolved_by_id ON public.booking_cancel_requests USING btree (resolved_by_id);


--
-- Name: index_booking_days_on_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_days_on_booking_id ON public.booking_days USING btree (booking_id);


--
-- Name: index_booking_days_on_booking_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_booking_days_on_booking_id_and_date ON public.booking_days USING btree (booking_id, date);


--
-- Name: index_booking_days_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_days_on_company_id ON public.booking_days USING btree (company_id);


--
-- Name: index_booking_days_on_company_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_days_on_company_id_and_date ON public.booking_days USING btree (company_id, date);


--
-- Name: index_booking_events_on_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_events_on_booking_id ON public.booking_events USING btree (booking_id);


--
-- Name: index_booking_events_on_booking_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_events_on_booking_trip_id ON public.booking_events USING btree (booking_trip_id);


--
-- Name: index_booking_events_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_events_on_company_id ON public.booking_events USING btree (company_id);


--
-- Name: index_booking_events_on_company_id_and_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_events_on_company_id_and_occurred_at ON public.booking_events USING btree (company_id, occurred_at);


--
-- Name: index_booking_trip_changes_on_booking_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trip_changes_on_booking_trip_id ON public.booking_trip_changes USING btree (booking_trip_id);


--
-- Name: index_booking_trip_changes_on_changed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trip_changes_on_changed_by_id ON public.booking_trip_changes USING btree (changed_by_id);


--
-- Name: index_booking_trip_changes_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trip_changes_on_company_id ON public.booking_trip_changes USING btree (company_id);


--
-- Name: index_booking_trip_points_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trip_points_on_company_id ON public.booking_trip_points USING btree (company_id);


--
-- Name: index_booking_trip_standbys_on_booking_trip_id_and_leg; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_booking_trip_standbys_on_booking_trip_id_and_leg ON public.booking_trip_standbys USING btree (booking_trip_id, leg);


--
-- Name: index_booking_trip_standbys_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trip_standbys_on_company_id ON public.booking_trip_standbys USING btree (company_id);


--
-- Name: index_booking_trip_vehicles_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trip_vehicles_on_company_id ON public.booking_trip_vehicles USING btree (company_id);


--
-- Name: index_booking_trip_vehicles_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trip_vehicles_on_vehicle_type_id ON public.booking_trip_vehicles USING btree (vehicle_type_id);


--
-- Name: index_booking_trips_on_booking_day_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trips_on_booking_day_id ON public.booking_trips USING btree (booking_day_id);


--
-- Name: index_booking_trips_on_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trips_on_booking_id ON public.booking_trips USING btree (booking_id);


--
-- Name: index_booking_trips_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trips_on_company_id ON public.booking_trips USING btree (company_id);


--
-- Name: index_booking_trips_on_company_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_trips_on_company_id_and_status ON public.booking_trips USING btree (company_id, status);


--
-- Name: index_bookings_on_client_end_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_client_end_customer_id ON public.bookings USING btree (client_end_customer_id);


--
-- Name: index_bookings_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_client_id ON public.bookings USING btree (client_id);


--
-- Name: index_bookings_on_client_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_client_site_id ON public.bookings USING btree (client_site_id);


--
-- Name: index_bookings_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_company_id ON public.bookings USING btree (company_id);


--
-- Name: index_bookings_on_company_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_company_id_and_created_at ON public.bookings USING btree (company_id, created_at);


--
-- Name: index_bookings_on_company_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bookings_on_company_id_and_number ON public.bookings USING btree (company_id, number);


--
-- Name: index_bookings_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_created_by_id ON public.bookings USING btree (created_by_id);


--
-- Name: index_bus_request_answer_moves_on_bus_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_request_answer_moves_on_bus_request_id ON public.bus_request_answer_moves USING btree (bus_request_id);


--
-- Name: index_bus_request_events_on_bus_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_request_events_on_bus_request_id ON public.bus_request_events USING btree (bus_request_id);


--
-- Name: index_bus_request_places_on_bus_request_id_and_session; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bus_request_places_on_bus_request_id_and_session ON public.bus_request_places USING btree (bus_request_id, session);


--
-- Name: index_bus_request_places_on_school_route_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_request_places_on_school_route_id ON public.bus_request_places USING btree (school_route_id);


--
-- Name: index_bus_requests_on_academic_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_requests_on_academic_year_id ON public.bus_requests USING btree (academic_year_id);


--
-- Name: index_bus_requests_on_company_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bus_requests_on_company_id_and_code ON public.bus_requests USING btree (company_id, code);


--
-- Name: index_bus_requests_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_requests_on_family_id ON public.bus_requests USING btree (family_id);


--
-- Name: index_bus_requests_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_requests_on_school_id ON public.bus_requests USING btree (school_id);


--
-- Name: index_bus_requests_on_school_id_and_kind_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_requests_on_school_id_and_kind_and_status ON public.bus_requests USING btree (school_id, kind, status);


--
-- Name: index_bus_requests_on_school_rider_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_requests_on_school_rider_id ON public.bus_requests USING btree (school_rider_id);


--
-- Name: index_bus_session_variants_on_bus_session_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_session_variants_on_bus_session_id_and_position ON public.bus_session_variants USING btree (bus_session_id, "position");


--
-- Name: index_bus_sessions_on_academic_year_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bus_sessions_on_academic_year_id_and_position ON public.bus_sessions USING btree (academic_year_id, "position");


--
-- Name: index_calendar_days_on_calendar_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_days_on_calendar_id ON public.calendar_days USING btree (calendar_id);


--
-- Name: index_calendar_days_on_calendar_id_and_starts_on_and_ends_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_days_on_calendar_id_and_starts_on_and_ends_on ON public.calendar_days USING btree (calendar_id, starts_on, ends_on);


--
-- Name: index_calendar_days_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_days_on_company_id ON public.calendar_days USING btree (company_id);


--
-- Name: index_calendars_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendars_on_company_id ON public.calendars USING btree (company_id);


--
-- Name: index_calendars_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_calendars_on_company_id_and_name ON public.calendars USING btree (company_id, name) WHERE (discarded_at IS NULL);


--
-- Name: index_calendars_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendars_on_discarded_at ON public.calendars USING btree (discarded_at);


--
-- Name: index_cca_bookings_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cca_bookings_on_family_id ON public.cca_bookings USING btree (family_id);


--
-- Name: index_cca_bookings_on_family_id_and_child_name_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cca_bookings_on_family_id_and_child_name_and_date ON public.cca_bookings USING btree (family_id, child_name, date);


--
-- Name: index_cca_bookings_on_school_bill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cca_bookings_on_school_bill_id ON public.cca_bookings USING btree (school_bill_id);


--
-- Name: index_cca_bookings_on_school_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cca_bookings_on_school_id_and_date ON public.cca_bookings USING btree (school_id, date);


--
-- Name: index_cca_credits_on_cca_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cca_credits_on_cca_booking_id ON public.cca_credits USING btree (cca_booking_id);


--
-- Name: index_cca_credits_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cca_credits_on_family_id ON public.cca_credits USING btree (family_id);


--
-- Name: index_cca_off_days_on_school_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cca_off_days_on_school_id_and_date ON public.cca_off_days USING btree (school_id, date);


--
-- Name: index_cca_ride_settings_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cca_ride_settings_on_school_id ON public.cca_ride_settings USING btree (school_id);


--
-- Name: index_client_billing_contacts_on_billable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_billing_contacts_on_billable ON public.client_billing_contacts USING btree (billable_type, billable_id);


--
-- Name: index_client_billing_contacts_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_billing_contacts_on_company_id ON public.client_billing_contacts USING btree (company_id);


--
-- Name: index_client_billing_contacts_unique_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_billing_contacts_unique_email ON public.client_billing_contacts USING btree (billable_type, billable_id, email) WHERE (email IS NOT NULL);


--
-- Name: index_client_bookable_vehicle_types_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_bookable_vehicle_types_on_company_id ON public.client_bookable_vehicle_types USING btree (company_id);


--
-- Name: index_client_bookable_vehicle_types_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_bookable_vehicle_types_on_vehicle_type_id ON public.client_bookable_vehicle_types USING btree (vehicle_type_id);


--
-- Name: index_client_end_customers_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_end_customers_on_client_id ON public.client_end_customers USING btree (client_id);


--
-- Name: index_client_end_customers_on_client_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_end_customers_on_client_id_and_name ON public.client_end_customers USING btree (client_id, name);


--
-- Name: index_client_end_customers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_end_customers_on_company_id ON public.client_end_customers USING btree (company_id);


--
-- Name: index_client_invoice_line_runs_billed_once; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_invoice_line_runs_billed_once ON public.client_invoice_line_runs USING btree (occurrence_id, occurrence_date) WHERE active;


--
-- Name: index_client_invoice_line_runs_on_client_invoice_line_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoice_line_runs_on_client_invoice_line_id ON public.client_invoice_line_runs USING btree (client_invoice_line_id);


--
-- Name: index_client_invoice_lines_on_client_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoice_lines_on_client_invoice_id ON public.client_invoice_lines USING btree (client_invoice_id);


--
-- Name: index_client_invoice_lines_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoice_lines_on_trip_id ON public.client_invoice_lines USING btree (trip_id);


--
-- Name: index_client_invoice_payments_on_client_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoice_payments_on_client_invoice_id ON public.client_invoice_payments USING btree (client_invoice_id);


--
-- Name: index_client_invoice_payments_on_recorded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoice_payments_on_recorded_by_id ON public.client_invoice_payments USING btree (recorded_by_id);


--
-- Name: index_client_invoice_sends_on_client_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoice_sends_on_client_invoice_id ON public.client_invoice_sends USING btree (client_invoice_id);


--
-- Name: index_client_invoice_sends_on_sent_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoice_sends_on_sent_by_id ON public.client_invoice_sends USING btree (sent_by_id);


--
-- Name: index_client_invoices_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoices_on_client_id ON public.client_invoices USING btree (client_id);


--
-- Name: index_client_invoices_on_client_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoices_on_client_site_id ON public.client_invoices USING btree (client_site_id);


--
-- Name: index_client_invoices_on_company_id_and_kind_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoices_on_company_id_and_kind_and_status ON public.client_invoices USING btree (company_id, kind, status);


--
-- Name: index_client_invoices_on_company_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_invoices_on_company_id_and_number ON public.client_invoices USING btree (company_id, number) WHERE (number IS NOT NULL);


--
-- Name: index_client_invoices_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoices_on_created_by_id ON public.client_invoices USING btree (created_by_id);


--
-- Name: index_client_invoices_on_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoices_on_invoice_id ON public.client_invoices USING btree (invoice_id);


--
-- Name: index_client_invoices_on_issued_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoices_on_issued_by_id ON public.client_invoices USING btree (issued_by_id);


--
-- Name: index_client_invoices_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoices_on_trip_id ON public.client_invoices USING btree (trip_id);


--
-- Name: index_client_invoices_on_voided_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_invoices_on_voided_by_id ON public.client_invoices USING btree (voided_by_id);


--
-- Name: index_client_pickup_points_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_pickup_points_on_client_id ON public.client_pickup_points USING btree (client_id);


--
-- Name: index_client_pickup_points_on_client_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_pickup_points_on_client_id_and_name ON public.client_pickup_points USING btree (client_id, name);


--
-- Name: index_client_pickup_points_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_pickup_points_on_company_id ON public.client_pickup_points USING btree (company_id);


--
-- Name: index_client_pickup_points_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_pickup_points_on_created_by_id ON public.client_pickup_points USING btree (created_by_id);


--
-- Name: index_client_sites_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_sites_on_client_id ON public.client_sites USING btree (client_id);


--
-- Name: index_client_sites_on_client_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_sites_on_client_id_and_name ON public.client_sites USING btree (client_id, name);


--
-- Name: index_client_sites_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_sites_on_company_id ON public.client_sites USING btree (company_id);


--
-- Name: index_client_sites_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_sites_on_created_by_id ON public.client_sites USING btree (created_by_id);


--
-- Name: index_client_sites_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_sites_on_school_id ON public.client_sites USING btree (school_id) WHERE (school_id IS NOT NULL);


--
-- Name: index_client_user_sites_on_client_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_user_sites_on_client_site_id ON public.client_user_sites USING btree (client_site_id);


--
-- Name: index_client_user_sites_on_client_user_id_and_client_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_user_sites_on_client_user_id_and_client_site_id ON public.client_user_sites USING btree (client_user_id, client_site_id);


--
-- Name: index_client_users_on_client_id_and_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_users_on_client_id_and_email ON public.client_users USING btree (client_id, email) WHERE (discarded_at IS NULL);


--
-- Name: index_client_users_on_company_id_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_users_on_company_id_and_client_id ON public.client_users USING btree (company_id, client_id);


--
-- Name: index_client_users_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_users_on_created_by_id ON public.client_users USING btree (created_by_id);


--
-- Name: index_client_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_users_on_email ON public.client_users USING btree (email);


--
-- Name: index_client_users_on_portal_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_users_on_portal_account_id ON public.client_users USING btree (portal_account_id);


--
-- Name: index_clients_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clients_on_company_id ON public.clients USING btree (company_id);


--
-- Name: index_clients_on_company_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_clients_on_company_id_and_code ON public.clients USING btree (company_id, code);


--
-- Name: index_clients_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_clients_on_company_id_and_name ON public.clients USING btree (company_id, name) WHERE (discarded_at IS NULL);


--
-- Name: index_clients_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clients_on_discarded_at ON public.clients USING btree (discarded_at);


--
-- Name: index_clients_on_rate_card_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clients_on_rate_card_id ON public.clients USING btree (rate_card_id);


--
-- Name: index_companies_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_companies_on_code ON public.companies USING btree (code);


--
-- Name: index_companies_on_country_set_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_companies_on_country_set_by_id ON public.companies USING btree (country_set_by_id);


--
-- Name: index_company_country_requests_on_company_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_country_requests_on_company_id_and_created_at ON public.company_country_requests USING btree (company_id, created_at);


--
-- Name: index_company_country_requests_on_decided_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_country_requests_on_decided_by_id ON public.company_country_requests USING btree (decided_by_id);


--
-- Name: index_company_country_requests_on_requested_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_country_requests_on_requested_by_id ON public.company_country_requests USING btree (requested_by_id);


--
-- Name: index_company_country_requests_on_status_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_country_requests_on_status_and_created_at ON public.company_country_requests USING btree (status, created_at);


--
-- Name: index_company_country_requests_one_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_company_country_requests_one_pending ON public.company_country_requests USING btree (company_id) WHERE ((status)::text = 'pending'::text);


--
-- Name: index_company_lead_domains_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_company_lead_domains_on_domain ON public.company_lead_domains USING btree (domain);


--
-- Name: index_company_lead_domains_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_lead_domains_on_updated_by_id ON public.company_lead_domains USING btree (updated_by_id);


--
-- Name: index_company_leads_on_domain_and_asked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_leads_on_domain_and_asked_at ON public.company_leads USING btree (domain, asked_at);


--
-- Name: index_company_sequences_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_sequences_on_company_id ON public.company_sequences USING btree (company_id);


--
-- Name: index_company_sequences_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_company_sequences_on_company_id_and_name ON public.company_sequences USING btree (company_id, name);


--
-- Name: index_dashboard_layouts_on_user_id_and_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dashboard_layouts_on_user_id_and_company_id ON public.dashboard_layouts USING btree (user_id, company_id);


--
-- Name: index_disabled_vehicle_types_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disabled_vehicle_types_on_company_id ON public.disabled_vehicle_types USING btree (company_id);


--
-- Name: index_disabled_vehicle_types_on_company_id_and_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_disabled_vehicle_types_on_company_id_and_vehicle_type_id ON public.disabled_vehicle_types USING btree (company_id, vehicle_type_id);


--
-- Name: index_disabled_vehicle_types_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disabled_vehicle_types_on_vehicle_type_id ON public.disabled_vehicle_types USING btree (vehicle_type_id);


--
-- Name: index_discover_advertisers_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discover_advertisers_on_name ON public.discover_advertisers USING btree (name) WHERE (discarded_at IS NULL);


--
-- Name: index_discover_placements_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discover_placements_on_created_by_id ON public.discover_placements USING btree (created_by_id);


--
-- Name: index_discover_placements_on_discover_advertiser_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discover_placements_on_discover_advertiser_id ON public.discover_placements USING btree (discover_advertiser_id);


--
-- Name: index_discover_placements_on_run_by_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discover_placements_on_run_by_company_id ON public.discover_placements USING btree (run_by_company_id);


--
-- Name: index_discover_placements_on_status_and_starts_on_and_ends_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discover_placements_on_status_and_starts_on_and_ends_on ON public.discover_placements USING btree (status, starts_on, ends_on);


--
-- Name: index_document_reads_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_reads_on_company_id ON public.document_reads USING btree (company_id);


--
-- Name: index_document_reads_on_company_id_and_kind_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_reads_on_company_id_and_kind_and_created_at ON public.document_reads USING btree (company_id, kind, created_at);


--
-- Name: index_document_reads_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_reads_on_user_id ON public.document_reads USING btree (user_id);


--
-- Name: index_driver_app_sessions_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_app_sessions_on_company_id ON public.driver_app_sessions USING btree (company_id);


--
-- Name: index_driver_app_sessions_on_driver_id_and_signed_in_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_app_sessions_on_driver_id_and_signed_in_at ON public.driver_app_sessions USING btree (driver_id, signed_in_at) WHERE (driver_id IS NOT NULL);


--
-- Name: index_driver_app_sessions_on_tracking_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_app_sessions_on_tracking_device_id ON public.driver_app_sessions USING btree (tracking_device_id);


--
-- Name: index_driver_invites_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_invites_on_company_id ON public.driver_invites USING btree (company_id);


--
-- Name: index_driver_invites_on_invitable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_invites_on_invitable ON public.driver_invites USING btree (invitable_type, invitable_id);


--
-- Name: index_driver_invites_on_sent_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_invites_on_sent_by_id ON public.driver_invites USING btree (sent_by_id);


--
-- Name: index_driver_kyc_profiles_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_kyc_profiles_on_company_id ON public.driver_kyc_profiles USING btree (company_id);


--
-- Name: index_driver_kyc_profiles_on_driver; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_driver_kyc_profiles_on_driver ON public.driver_kyc_profiles USING btree (driver_type, driver_id);


--
-- Name: index_driver_pay_month_lines_on_driver_pay_month_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_pay_month_lines_on_driver_pay_month_id ON public.driver_pay_month_lines USING btree (driver_pay_month_id);


--
-- Name: index_driver_pay_month_runs_on_driver_pay_month_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_pay_month_runs_on_driver_pay_month_id ON public.driver_pay_month_runs USING btree (driver_pay_month_id);


--
-- Name: index_driver_pay_months_on_company_id_and_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_pay_months_on_company_id_and_month ON public.driver_pay_months USING btree (company_id, month);


--
-- Name: index_driver_pay_months_on_confirmed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_pay_months_on_confirmed_by_id ON public.driver_pay_months USING btree (confirmed_by_id);


--
-- Name: index_driver_pay_months_on_driver_id_and_month; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_driver_pay_months_on_driver_id_and_month ON public.driver_pay_months USING btree (driver_id, month);


--
-- Name: index_driver_pay_schemes_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_pay_schemes_on_company_id ON public.driver_pay_schemes USING btree (company_id);


--
-- Name: index_driver_pay_schemes_on_driver_id_and_starts_on; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_driver_pay_schemes_on_driver_id_and_starts_on ON public.driver_pay_schemes USING btree (driver_id, starts_on);


--
-- Name: index_driver_pay_schemes_on_pay_scheme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_pay_schemes_on_pay_scheme_id ON public.driver_pay_schemes USING btree (pay_scheme_id);


--
-- Name: index_driver_point_allocations_on_driver_point_deduction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_allocations_on_driver_point_deduction_id ON public.driver_point_allocations USING btree (driver_point_deduction_id);


--
-- Name: index_driver_point_allocations_on_driver_point_lot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_allocations_on_driver_point_lot_id ON public.driver_point_allocations USING btree (driver_point_lot_id);


--
-- Name: index_driver_point_deductions_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_deductions_on_company_id ON public.driver_point_deductions USING btree (company_id);


--
-- Name: index_driver_point_deductions_on_deducted_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_deductions_on_deducted_by_id ON public.driver_point_deductions USING btree (deducted_by_id);


--
-- Name: index_driver_point_deductions_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_deductions_on_driver_id ON public.driver_point_deductions USING btree (driver_id);


--
-- Name: index_driver_point_lots_on_awarded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_lots_on_awarded_by_id ON public.driver_point_lots USING btree (awarded_by_id);


--
-- Name: index_driver_point_lots_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_lots_on_company_id ON public.driver_point_lots USING btree (company_id);


--
-- Name: index_driver_point_lots_on_driver_id_and_expires_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_lots_on_driver_id_and_expires_on ON public.driver_point_lots USING btree (driver_id, expires_on);


--
-- Name: index_driver_point_lots_on_driver_pay_month_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_lots_on_driver_pay_month_id ON public.driver_point_lots USING btree (driver_pay_month_id);


--
-- Name: index_driver_point_lots_on_pay_bonus_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_point_lots_on_pay_bonus_id ON public.driver_point_lots USING btree (pay_bonus_id);


--
-- Name: index_driver_vehicle_types_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_vehicle_types_on_company_id ON public.driver_vehicle_types USING btree (company_id);


--
-- Name: index_driver_vehicle_types_on_driver_id_and_starts_on; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_driver_vehicle_types_on_driver_id_and_starts_on ON public.driver_vehicle_types USING btree (driver_id, starts_on);


--
-- Name: index_driver_vehicle_types_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_driver_vehicle_types_on_vehicle_type_id ON public.driver_vehicle_types USING btree (vehicle_type_id);


--
-- Name: index_drivers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drivers_on_company_id ON public.drivers USING btree (company_id);


--
-- Name: index_drivers_on_company_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drivers_on_company_id_and_status ON public.drivers USING btree (company_id, status);


--
-- Name: index_drivers_on_display_set_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drivers_on_display_set_by_id ON public.drivers USING btree (display_set_by_id);


--
-- Name: index_drivers_on_last_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drivers_on_last_vehicle_id ON public.drivers USING btree (last_vehicle_id);


--
-- Name: index_drivers_on_live_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_drivers_on_live_phone ON public.drivers USING btree (company_id, phone) WHERE (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('active'::character varying)::text])) AND (discarded_at IS NULL));


--
-- Name: index_external_share_links_one_live; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_external_share_links_one_live ON public.external_vehicle_share_links USING btree (company_id) WHERE (revoked_at IS NULL);


--
-- Name: index_external_vehicle_share_links_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_vehicle_share_links_on_company_id ON public.external_vehicle_share_links USING btree (company_id);


--
-- Name: index_external_vehicle_share_links_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_vehicle_share_links_on_created_by_id ON public.external_vehicle_share_links USING btree (created_by_id);


--
-- Name: index_external_vehicle_share_links_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_external_vehicle_share_links_on_token ON public.external_vehicle_share_links USING btree (token);


--
-- Name: index_external_vehicle_submissions_on_decided_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_vehicle_submissions_on_decided_by_id ON public.external_vehicle_submissions USING btree (decided_by_id);


--
-- Name: index_external_vehicle_submissions_on_share_link_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_vehicle_submissions_on_share_link_id ON public.external_vehicle_submissions USING btree (share_link_id);


--
-- Name: index_external_vehicle_submissions_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_vehicle_submissions_on_vehicle_id ON public.external_vehicle_submissions USING btree (vehicle_id);


--
-- Name: index_families_on_company_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_families_on_company_id_and_code ON public.families USING btree (company_id, code);


--
-- Name: index_families_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_families_on_school_id ON public.families USING btree (school_id);


--
-- Name: index_family_guardians_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_family_guardians_on_email ON public.family_guardians USING btree (email);


--
-- Name: index_family_guardians_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_family_guardians_on_family_id ON public.family_guardians USING btree (family_id);


--
-- Name: index_family_guardians_on_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_family_guardians_on_phone ON public.family_guardians USING btree (phone);


--
-- Name: index_family_riders_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_family_riders_on_family_id ON public.family_riders USING btree (family_id);


--
-- Name: index_family_riders_on_school_id_and_rid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_family_riders_on_school_id_and_rid ON public.family_riders USING btree (school_id, rid);


--
-- Name: index_fare_adjustments_on_academic_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fare_adjustments_on_academic_year_id ON public.fare_adjustments USING btree (academic_year_id);


--
-- Name: index_fare_adjustments_on_school_id_and_from_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fare_adjustments_on_school_id_and_from_month ON public.fare_adjustments USING btree (school_id, from_month);


--
-- Name: index_fare_bus_rates_on_fare_table_id_and_bus_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_fare_bus_rates_on_fare_table_id_and_bus_type ON public.fare_bus_rates USING btree (fare_table_id, bus_type);


--
-- Name: index_fare_size_columns_on_fare_table_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fare_size_columns_on_fare_table_id_and_position ON public.fare_size_columns USING btree (fare_table_id, "position");


--
-- Name: index_fare_surcharges_on_fare_table_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fare_surcharges_on_fare_table_id_and_position ON public.fare_surcharges USING btree (fare_table_id, "position");


--
-- Name: index_fare_tables_on_academic_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_fare_tables_on_academic_year_id ON public.fare_tables USING btree (academic_year_id);


--
-- Name: index_fare_tier_sizes_on_fare_tier_id_and_fare_size_column_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_fare_tier_sizes_on_fare_tier_id_and_fare_size_column_id ON public.fare_tier_sizes USING btree (fare_tier_id, fare_size_column_id);


--
-- Name: index_fare_tiers_on_fare_table_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fare_tiers_on_fare_table_id_and_position ON public.fare_tiers USING btree (fare_table_id, "position");


--
-- Name: index_feasibility_rows_on_feasibility_study_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feasibility_rows_on_feasibility_study_id ON public.feasibility_rows USING btree (feasibility_study_id);


--
-- Name: index_feasibility_scenarios_on_feasibility_study_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feasibility_scenarios_on_feasibility_study_id ON public.feasibility_scenarios USING btree (feasibility_study_id);


--
-- Name: index_feasibility_studies_on_company_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feasibility_studies_on_company_id_and_updated_at ON public.feasibility_studies USING btree (company_id, updated_at);


--
-- Name: index_finance_approvers_on_company_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_finance_approvers_on_company_id_and_user_id ON public.finance_approvers USING btree (company_id, user_id);


--
-- Name: index_finance_approvers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_finance_approvers_on_user_id ON public.finance_approvers USING btree (user_id);


--
-- Name: index_finance_settings_on_bank_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_finance_settings_on_bank_id ON public.finance_settings USING btree (bank_id);


--
-- Name: index_finance_settings_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_finance_settings_on_company_id ON public.finance_settings USING btree (company_id);


--
-- Name: index_finance_settings_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_finance_settings_on_locked_by_id ON public.finance_settings USING btree (locked_by_id);


--
-- Name: index_fuel_alerts_on_checked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_alerts_on_checked_by_id ON public.fuel_alerts USING btree (checked_by_id);


--
-- Name: index_fuel_alerts_on_company_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_fuel_alerts_on_company_id_and_key ON public.fuel_alerts USING btree (company_id, key);


--
-- Name: index_fuel_alerts_on_company_id_and_status_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_alerts_on_company_id_and_status_and_date ON public.fuel_alerts USING btree (company_id, status, date);


--
-- Name: index_fuel_alerts_on_fuel_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_alerts_on_fuel_entry_id ON public.fuel_alerts USING btree (fuel_entry_id);


--
-- Name: index_fuel_alerts_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_alerts_on_vehicle_id ON public.fuel_alerts USING btree (vehicle_id);


--
-- Name: index_fuel_companies_on_company_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_fuel_companies_on_company_and_name ON public.fuel_companies USING btree (company_id, lower((name)::text));


--
-- Name: index_fuel_entries_on_company_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_entries_on_company_id_and_date ON public.fuel_entries USING btree (company_id, date);


--
-- Name: index_fuel_entries_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_entries_on_created_by_id ON public.fuel_entries USING btree (created_by_id);


--
-- Name: index_fuel_entries_on_document_read_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_entries_on_document_read_id ON public.fuel_entries USING btree (document_read_id);


--
-- Name: index_fuel_entries_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_entries_on_driver_id ON public.fuel_entries USING btree (driver_id);


--
-- Name: index_fuel_entries_on_fuel_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_entries_on_fuel_company_id ON public.fuel_entries USING btree (fuel_company_id);


--
-- Name: index_fuel_entries_on_vehicle_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fuel_entries_on_vehicle_id_and_date ON public.fuel_entries USING btree (vehicle_id, date);


--
-- Name: index_maintenance_invoices_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_invoices_on_company_id ON public.maintenance_invoices USING btree (company_id);


--
-- Name: index_maintenance_invoices_on_maintenance_visit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_invoices_on_maintenance_visit_id ON public.maintenance_invoices USING btree (maintenance_visit_id);


--
-- Name: index_maintenance_lines_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_lines_on_company_id ON public.maintenance_lines USING btree (company_id);


--
-- Name: index_maintenance_lines_on_maintenance_visit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_lines_on_maintenance_visit_id ON public.maintenance_lines USING btree (maintenance_visit_id);


--
-- Name: index_maintenance_visits_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_visits_on_company_id ON public.maintenance_visits USING btree (company_id);


--
-- Name: index_maintenance_visits_on_company_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_visits_on_company_id_and_date ON public.maintenance_visits USING btree (company_id, date);


--
-- Name: index_maintenance_visits_on_completed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_visits_on_completed_by_id ON public.maintenance_visits USING btree (completed_by_id);


--
-- Name: index_maintenance_visits_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_visits_on_created_by_id ON public.maintenance_visits USING btree (created_by_id);


--
-- Name: index_maintenance_visits_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_visits_on_driver_id ON public.maintenance_visits USING btree (driver_id);


--
-- Name: index_maintenance_visits_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_visits_on_vehicle_id ON public.maintenance_visits USING btree (vehicle_id);


--
-- Name: index_maintenance_visits_on_vehicle_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_visits_on_vehicle_id_and_date ON public.maintenance_visits USING btree (vehicle_id, date);


--
-- Name: index_maintenance_visits_on_workshop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_maintenance_visits_on_workshop_id ON public.maintenance_visits USING btree (workshop_id);


--
-- Name: index_message_terms_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_terms_on_created_by_id ON public.message_terms USING btree (created_by_id);


--
-- Name: index_message_terms_on_lower_term; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_message_terms_on_lower_term ON public.message_terms USING btree (lower((term)::text));


--
-- Name: index_notice_deliveries_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_deliveries_on_company_id ON public.notice_deliveries USING btree (company_id);


--
-- Name: index_notice_deliveries_on_notice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_deliveries_on_notice_id ON public.notice_deliveries USING btree (notice_id);


--
-- Name: index_notice_routes_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_routes_on_company_id ON public.notice_routes USING btree (company_id);


--
-- Name: index_notice_routes_on_notice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_routes_on_notice_id ON public.notice_routes USING btree (notice_id);


--
-- Name: index_notice_routes_on_school_route_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_routes_on_school_route_id ON public.notice_routes USING btree (school_route_id);


--
-- Name: index_notice_runs_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_runs_on_company_id ON public.notice_runs USING btree (company_id);


--
-- Name: index_notice_runs_on_notice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_runs_on_notice_id ON public.notice_runs USING btree (notice_id);


--
-- Name: index_notice_runs_on_notice_id_and_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notice_runs_on_notice_id_and_trip_run_id ON public.notice_runs USING btree (notice_id, trip_run_id);


--
-- Name: index_notice_runs_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_runs_on_trip_run_id ON public.notice_runs USING btree (trip_run_id);


--
-- Name: index_notice_templates_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notice_templates_on_company_id ON public.notice_templates USING btree (company_id);


--
-- Name: index_notice_templates_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notice_templates_on_company_id_and_name ON public.notice_templates USING btree (company_id, name);


--
-- Name: index_notices_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notices_on_company_id ON public.notices USING btree (company_id);


--
-- Name: index_notices_on_company_id_and_starts_at_and_ends_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notices_on_company_id_and_starts_at_and_ends_at ON public.notices USING btree (company_id, starts_at, ends_at);


--
-- Name: index_notices_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notices_on_created_by_id ON public.notices USING btree (created_by_id);


--
-- Name: index_notices_on_ended_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notices_on_ended_by_id ON public.notices USING btree (ended_by_id);


--
-- Name: index_notices_on_notice_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notices_on_notice_template_id ON public.notices USING btree (notice_template_id);


--
-- Name: index_notices_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notices_on_trip_id ON public.notices USING btree (trip_id);


--
-- Name: index_notification_emails_on_booking_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_emails_on_booking_event_id ON public.notification_emails USING btree (booking_event_id);


--
-- Name: index_notification_emails_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_emails_on_company_id ON public.notification_emails USING btree (company_id);


--
-- Name: index_notification_emails_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_emails_on_user_id ON public.notification_emails USING btree (user_id);


--
-- Name: index_occurrence_correction_logs_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_correction_logs_on_company_id ON public.occurrence_correction_logs USING btree (company_id);


--
-- Name: index_occurrence_correction_logs_on_occurrence_correction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_correction_logs_on_occurrence_correction_id ON public.occurrence_correction_logs USING btree (occurrence_correction_id);


--
-- Name: index_occurrence_correction_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_correction_logs_on_user_id ON public.occurrence_correction_logs USING btree (user_id);


--
-- Name: index_occurrence_correction_stops_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_correction_stops_on_company_id ON public.occurrence_correction_stops USING btree (company_id);


--
-- Name: index_occurrence_corrections_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_corrections_on_company_id ON public.occurrence_corrections USING btree (company_id);


--
-- Name: index_occurrence_corrections_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_corrections_on_driver_id ON public.occurrence_corrections USING btree (driver_id);


--
-- Name: index_occurrence_corrections_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_corrections_on_vehicle_id ON public.occurrence_corrections USING btree (vehicle_id);


--
-- Name: index_occurrence_driver_reports_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_driver_reports_on_company_id ON public.occurrence_driver_reports USING btree (company_id);


--
-- Name: index_occurrence_notes_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_notes_on_author_id ON public.occurrence_notes USING btree (author_id);


--
-- Name: index_occurrence_notes_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_notes_on_company_id ON public.occurrence_notes USING btree (company_id);


--
-- Name: index_occurrence_notes_on_occurrence_id_and_occurrence_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_notes_on_occurrence_id_and_occurrence_date ON public.occurrence_notes USING btree (occurrence_id, occurrence_date);


--
-- Name: index_occurrence_positions_on_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_positions_on_recorded_at ON ONLY public.occurrence_positions USING brin (recorded_at);


--
-- Name: index_occurrence_positions_on_run; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_positions_on_run ON ONLY public.occurrence_positions USING btree (occurrence_id, occurrence_date, recorded_at);


--
-- Name: index_occurrence_report_photos_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_report_photos_on_company_id ON public.occurrence_report_photos USING btree (company_id);


--
-- Name: index_occurrence_report_photos_on_occurrence_driver_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_report_photos_on_occurrence_driver_report_id ON public.occurrence_report_photos USING btree (occurrence_driver_report_id);


--
-- Name: index_occurrence_stop_events_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_stop_events_on_company_id ON public.occurrence_stop_events USING btree (company_id);


--
-- Name: index_occurrence_trip_summaries_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_occurrence_trip_summaries_on_company_id ON public.occurrence_trip_summaries USING btree (company_id);


--
-- Name: index_operator_cost_overrides_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_cost_overrides_on_company_id ON public.operator_cost_overrides USING btree (company_id);


--
-- Name: index_operator_cost_overrides_on_set_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_cost_overrides_on_set_by_id ON public.operator_cost_overrides USING btree (set_by_id);


--
-- Name: index_operator_drivers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_drivers_on_company_id ON public.operator_drivers USING btree (company_id);


--
-- Name: index_operator_drivers_on_company_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_drivers_on_company_id_and_status ON public.operator_drivers USING btree (company_id, status);


--
-- Name: index_operator_drivers_on_display_set_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_drivers_on_display_set_by_id ON public.operator_drivers USING btree (display_set_by_id);


--
-- Name: index_operator_drivers_on_last_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_drivers_on_last_vehicle_id ON public.operator_drivers USING btree (last_vehicle_id);


--
-- Name: index_operator_drivers_on_live_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_operator_drivers_on_live_phone ON public.operator_drivers USING btree (company_id, phone) WHERE (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('active'::character varying)::text])) AND (discarded_at IS NULL));


--
-- Name: index_operator_drivers_on_operator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_drivers_on_operator_id ON public.operator_drivers USING btree (operator_id);


--
-- Name: index_operator_drivers_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_drivers_on_vehicle_id ON public.operator_drivers USING btree (vehicle_id);


--
-- Name: index_operator_drivers_one_per_vehicle; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_operator_drivers_one_per_vehicle ON public.operator_drivers USING btree (vehicle_id) WHERE (vehicle_id IS NOT NULL);


--
-- Name: index_operator_pay_batch_lines_on_approved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_batch_lines_on_approved_by_id ON public.operator_pay_batch_lines USING btree (approved_by_id);


--
-- Name: index_operator_pay_batch_lines_on_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_operator_pay_batch_lines_on_ref ON public.operator_pay_batch_lines USING btree (ref);


--
-- Name: index_operator_pay_batch_operators_on_operator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_batch_operators_on_operator_id ON public.operator_pay_batch_operators USING btree (operator_id);


--
-- Name: index_operator_pay_batch_operators_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_operator_pay_batch_operators_unique ON public.operator_pay_batch_operators USING btree (operator_pay_batch_id, operator_id);


--
-- Name: index_operator_pay_batches_on_bank_file_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_batches_on_bank_file_by_id ON public.operator_pay_batches USING btree (bank_file_by_id);


--
-- Name: index_operator_pay_batches_on_company_id_and_pay_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_batches_on_company_id_and_pay_date ON public.operator_pay_batches USING btree (company_id, pay_date);


--
-- Name: index_operator_pay_batches_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_batches_on_created_by_id ON public.operator_pay_batches USING btree (created_by_id);


--
-- Name: index_operator_pay_items_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_items_on_company_id ON public.operator_pay_items USING btree (company_id);


--
-- Name: index_operator_pay_items_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_items_on_created_by_id ON public.operator_pay_items USING btree (created_by_id);


--
-- Name: index_operator_pay_items_on_operator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_items_on_operator_id ON public.operator_pay_items USING btree (operator_id);


--
-- Name: index_operator_pay_payments_on_operator_pay_batch_operator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_payments_on_operator_pay_batch_operator_id ON public.operator_pay_payments USING btree (operator_pay_batch_operator_id);


--
-- Name: index_operator_pay_payments_on_recorded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_pay_payments_on_recorded_by_id ON public.operator_pay_payments USING btree (recorded_by_id);


--
-- Name: index_operators_on_bank_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operators_on_bank_id ON public.operators USING btree (bank_id);


--
-- Name: index_operators_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operators_on_company_id ON public.operators USING btree (company_id);


--
-- Name: index_operators_on_company_id_and_kind_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_operators_on_company_id_and_kind_and_name ON public.operators USING btree (company_id, kind, name) WHERE (discarded_at IS NULL);


--
-- Name: index_operators_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operators_on_discarded_at ON public.operators USING btree (discarded_at);


--
-- Name: index_ops_alerts_on_company_id_and_raised_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ops_alerts_on_company_id_and_raised_at ON public.ops_alerts USING btree (company_id, raised_at);


--
-- Name: index_ops_alerts_on_company_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ops_alerts_on_company_open ON public.ops_alerts USING btree (company_id) WHERE (cleared_at IS NULL);


--
-- Name: index_ops_alerts_open; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ops_alerts_open ON public.ops_alerts USING btree (occurrence_id, occurrence_date, kind, severity) WHERE (cleared_at IS NULL);


--
-- Name: index_pay_bonus_drivers_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_bonus_drivers_on_driver_id ON public.pay_bonus_drivers USING btree (driver_id);


--
-- Name: index_pay_bonus_drivers_on_pay_bonus_id_and_role_and_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_bonus_drivers_on_pay_bonus_id_and_role_and_driver_id ON public.pay_bonus_drivers USING btree (pay_bonus_id, role, driver_id);


--
-- Name: index_pay_bonus_drivers_on_signed_up_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_bonus_drivers_on_signed_up_by_id ON public.pay_bonus_drivers USING btree (signed_up_by_id);


--
-- Name: index_pay_bonus_excluded_periods_on_pay_bonus_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_bonus_excluded_periods_on_pay_bonus_id ON public.pay_bonus_excluded_periods USING btree (pay_bonus_id);


--
-- Name: index_pay_bonus_payments_on_pay_bonus_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_bonus_payments_on_pay_bonus_id ON public.pay_bonus_payments USING btree (pay_bonus_id);


--
-- Name: index_pay_bonus_schemes_on_pay_bonus_id_and_pay_scheme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_bonus_schemes_on_pay_bonus_id_and_pay_scheme_id ON public.pay_bonus_schemes USING btree (pay_bonus_id, pay_scheme_id);


--
-- Name: index_pay_bonus_schemes_on_pay_scheme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_bonus_schemes_on_pay_scheme_id ON public.pay_bonus_schemes USING btree (pay_scheme_id);


--
-- Name: index_pay_bonus_tiers_on_pay_bonus_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_bonus_tiers_on_pay_bonus_id ON public.pay_bonus_tiers USING btree (pay_bonus_id);


--
-- Name: index_pay_bonuses_on_company_id_and_starts_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_bonuses_on_company_id_and_starts_on ON public.pay_bonuses USING btree (company_id, starts_on);


--
-- Name: index_pay_bonuses_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_bonuses_on_locked_by_id ON public.pay_bonuses USING btree (locked_by_id);


--
-- Name: index_pay_rate_period_ranges_on_pay_rate_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_rate_period_ranges_on_pay_rate_period_id ON public.pay_rate_period_ranges USING btree (pay_rate_period_id);


--
-- Name: index_pay_rate_periods_on_pay_rate_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_rate_periods_on_pay_rate_plan_id ON public.pay_rate_periods USING btree (pay_rate_plan_id);


--
-- Name: index_pay_rate_plan_vehicle_types_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_rate_plan_vehicle_types_on_vehicle_type_id ON public.pay_rate_plan_vehicle_types USING btree (vehicle_type_id);


--
-- Name: index_pay_rate_plan_vehicle_types_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_rate_plan_vehicle_types_unique ON public.pay_rate_plan_vehicle_types USING btree (pay_rate_plan_id, vehicle_type_id);


--
-- Name: index_pay_rate_plans_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_rate_plans_on_company_id_and_name ON public.pay_rate_plans USING btree (company_id, name) WHERE (discarded_at IS NULL);


--
-- Name: index_pay_rate_plans_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_rate_plans_on_locked_by_id ON public.pay_rate_plans USING btree (locked_by_id);


--
-- Name: index_pay_rates_on_pay_rate_period_id_and_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_rates_on_pay_rate_period_id_and_vehicle_type_id ON public.pay_rates USING btree (pay_rate_period_id, vehicle_type_id);


--
-- Name: index_pay_rates_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_rates_on_vehicle_type_id ON public.pay_rates USING btree (vehicle_type_id);


--
-- Name: index_pay_rewards_on_company_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_rewards_on_company_id_and_status ON public.pay_rewards USING btree (company_id, status);


--
-- Name: index_pay_scheme_route_bands_on_pay_scheme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_scheme_route_bands_on_pay_scheme_id ON public.pay_scheme_route_bands USING btree (pay_scheme_id);


--
-- Name: index_pay_scheme_target_tiers_on_pay_scheme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_scheme_target_tiers_on_pay_scheme_id ON public.pay_scheme_target_tiers USING btree (pay_scheme_id);


--
-- Name: index_pay_scheme_volume_tiers_on_pay_scheme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_scheme_volume_tiers_on_pay_scheme_id ON public.pay_scheme_volume_tiers USING btree (pay_scheme_id);


--
-- Name: index_pay_schemes_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_schemes_on_company_id_and_name ON public.pay_schemes USING btree (company_id, name) WHERE (discarded_at IS NULL);


--
-- Name: index_pay_schemes_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_schemes_on_locked_by_id ON public.pay_schemes USING btree (locked_by_id);


--
-- Name: index_pay_schemes_on_pay_rate_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_schemes_on_pay_rate_plan_id ON public.pay_schemes USING btree (pay_rate_plan_id);


--
-- Name: index_pay_schemes_one_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_schemes_one_default ON public.pay_schemes USING btree (company_id) WHERE (is_default AND (discarded_at IS NULL));


--
-- Name: index_pay_simulator_templates_on_company_id_and_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_simulator_templates_on_company_id_and_slot ON public.pay_simulator_templates USING btree (company_id, slot);


--
-- Name: index_pay_simulator_templates_on_pay_scheme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_simulator_templates_on_pay_scheme_id ON public.pay_simulator_templates USING btree (pay_scheme_id);


--
-- Name: index_pay_simulator_templates_on_saved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_simulator_templates_on_saved_by_id ON public.pay_simulator_templates USING btree (saved_by_id);


--
-- Name: index_pay_simulator_templates_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_simulator_templates_on_vehicle_type_id ON public.pay_simulator_templates USING btree (vehicle_type_id);


--
-- Name: index_pickup_points_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pickup_points_on_company_id ON public.pickup_points USING btree (company_id);


--
-- Name: index_pickup_points_on_postal_codes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pickup_points_on_postal_codes ON public.pickup_points USING gin (postal_codes);


--
-- Name: index_plan_comments_on_school_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plan_comments_on_school_plan_id ON public.plan_comments USING btree (school_plan_id);


--
-- Name: index_portal_accounts_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_portal_accounts_on_email ON public.portal_accounts USING btree (email);


--
-- Name: index_portal_jwts_on_client_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_portal_jwts_on_client_user_id ON public.portal_jwts USING btree (client_user_id);


--
-- Name: index_portal_jwts_on_exp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_portal_jwts_on_exp ON public.portal_jwts USING btree (exp);


--
-- Name: index_portal_jwts_on_jti; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_portal_jwts_on_jti ON public.portal_jwts USING btree (jti);


--
-- Name: index_portal_jwts_on_portal_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_portal_jwts_on_portal_account_id ON public.portal_jwts USING btree (portal_account_id);


--
-- Name: index_portal_sign_in_codes_on_portal_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_portal_sign_in_codes_on_portal_account_id_and_created_at ON public.portal_sign_in_codes USING btree (portal_account_id, created_at);


--
-- Name: index_postal_geocodes_on_country_and_postal; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_postal_geocodes_on_country_and_postal ON public.postal_geocodes USING btree (country, postal);


--
-- Name: index_public_holidays_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_public_holidays_on_company_id ON public.public_holidays USING btree (company_id);


--
-- Name: index_public_holidays_on_company_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_public_holidays_on_company_id_and_date ON public.public_holidays USING btree (company_id, date);


--
-- Name: index_rate_card_amounts_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_amounts_on_company_id ON public.rate_card_amounts USING btree (company_id);


--
-- Name: index_rate_card_amounts_on_rate_card_distance_band_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_amounts_on_rate_card_distance_band_id ON public.rate_card_amounts USING btree (rate_card_distance_band_id);


--
-- Name: index_rate_card_amounts_on_rate_card_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_amounts_on_rate_card_id ON public.rate_card_amounts USING btree (rate_card_id);


--
-- Name: index_rate_card_amounts_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_amounts_on_vehicle_type_id ON public.rate_card_amounts USING btree (vehicle_type_id);


--
-- Name: index_rate_card_distance_bands_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_distance_bands_on_company_id ON public.rate_card_distance_bands USING btree (company_id);


--
-- Name: index_rate_card_distance_bands_on_rate_card_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_distance_bands_on_rate_card_id ON public.rate_card_distance_bands USING btree (rate_card_id);


--
-- Name: index_rate_card_periods_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_periods_on_company_id ON public.rate_card_periods USING btree (company_id);


--
-- Name: index_rate_card_periods_on_rate_card_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_periods_on_rate_card_id ON public.rate_card_periods USING btree (rate_card_id);


--
-- Name: index_rate_card_ranges_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_ranges_on_company_id ON public.rate_card_ranges USING btree (company_id);


--
-- Name: index_rate_card_ranges_on_rate_card_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_ranges_on_rate_card_period_id ON public.rate_card_ranges USING btree (rate_card_period_id);


--
-- Name: index_rate_card_rates_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_rates_on_company_id ON public.rate_card_rates USING btree (company_id);


--
-- Name: index_rate_card_rates_on_rate_card_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_rates_on_rate_card_period_id ON public.rate_card_rates USING btree (rate_card_period_id);


--
-- Name: index_rate_card_rates_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_rates_on_vehicle_type_id ON public.rate_card_rates USING btree (vehicle_type_id);


--
-- Name: index_rate_card_vehicle_types_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_vehicle_types_on_company_id ON public.rate_card_vehicle_types USING btree (company_id);


--
-- Name: index_rate_card_vehicle_types_on_rate_card_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_vehicle_types_on_rate_card_id ON public.rate_card_vehicle_types USING btree (rate_card_id);


--
-- Name: index_rate_card_vehicle_types_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_card_vehicle_types_on_vehicle_type_id ON public.rate_card_vehicle_types USING btree (vehicle_type_id);


--
-- Name: index_rate_cards_on_company_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rate_cards_on_company_and_name ON public.rate_cards USING btree (company_id, lower((name)::text));


--
-- Name: index_rate_cards_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rate_cards_on_company_id ON public.rate_cards USING btree (company_id);


--
-- Name: index_rate_cards_one_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rate_cards_one_default ON public.rate_cards USING btree (company_id) WHERE (default_card AND (archived_at IS NULL));


--
-- Name: index_registration_messages_on_school_registration_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_registration_messages_on_school_registration_id_and_key ON public.registration_messages USING btree (school_registration_id, key);


--
-- Name: index_replacement_notifications_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacement_notifications_on_company_id ON public.replacement_notifications USING btree (company_id);


--
-- Name: index_replacement_notifications_on_replacement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacement_notifications_on_replacement_id ON public.replacement_notifications USING btree (replacement_id);


--
-- Name: index_replacement_notifications_on_sent_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacement_notifications_on_sent_by_id ON public.replacement_notifications USING btree (sent_by_id);


--
-- Name: index_replacements_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_company_id ON public.replacements USING btree (company_id);


--
-- Name: index_replacements_on_company_id_and_starts_on_and_ends_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_company_id_and_starts_on_and_ends_on ON public.replacements USING btree (company_id, starts_on, ends_on);


--
-- Name: index_replacements_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_created_by_id ON public.replacements USING btree (created_by_id);


--
-- Name: index_replacements_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_driver_id ON public.replacements USING btree (driver_id);


--
-- Name: index_replacements_on_operator_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_operator_driver_id ON public.replacements USING btree (operator_driver_id);


--
-- Name: index_replacements_on_original_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_original_vehicle_id ON public.replacements USING btree (original_vehicle_id);


--
-- Name: index_replacements_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_trip_id ON public.replacements USING btree (trip_id);


--
-- Name: index_replacements_on_trip_id_and_run_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_trip_id_and_run_date ON public.replacements USING btree (trip_id, run_date);


--
-- Name: index_replacements_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_trip_run_id ON public.replacements USING btree (trip_run_id);


--
-- Name: index_replacements_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replacements_on_vehicle_id ON public.replacements USING btree (vehicle_id);


--
-- Name: index_rider_assignments_on_school_id_and_rid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rider_assignments_on_school_id_and_rid ON public.rider_assignments USING btree (school_id, rid);


--
-- Name: index_rider_assignments_on_school_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rider_assignments_on_school_plan_id ON public.rider_assignments USING btree (school_plan_id);


--
-- Name: index_rider_assignments_on_stop_point_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rider_assignments_on_stop_point_id ON public.rider_assignments USING btree (stop_point_id);


--
-- Name: index_rider_datasets_on_school_id_and_effective_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rider_datasets_on_school_id_and_effective_from ON public.rider_datasets USING btree (school_id, effective_from);


--
-- Name: index_rider_point_links_on_school_id_and_kind_and_postal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rider_point_links_on_school_id_and_kind_and_postal ON public.rider_point_links USING btree (school_id, kind, postal);


--
-- Name: index_rider_point_links_on_school_id_and_kind_and_rid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rider_point_links_on_school_id_and_kind_and_rid ON public.rider_point_links USING btree (school_id, kind, rid);


--
-- Name: index_rider_point_links_on_stop_point_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rider_point_links_on_stop_point_id ON public.rider_point_links USING btree (stop_point_id);


--
-- Name: index_route_charges_on_school_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_charges_on_school_id_and_status ON public.route_charges USING btree (school_id, status);


--
-- Name: index_route_charges_on_school_route_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_charges_on_school_route_id ON public.route_charges USING btree (school_route_id);


--
-- Name: index_route_list_version_stops_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_list_version_stops_on_company_id ON public.route_list_version_stops USING btree (company_id);


--
-- Name: index_route_list_version_stops_on_route_list_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_list_version_stops_on_route_list_version_id ON public.route_list_version_stops USING btree (route_list_version_id);


--
-- Name: index_route_list_version_students_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_list_version_students_on_company_id ON public.route_list_version_students USING btree (company_id);


--
-- Name: index_route_list_versions_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_list_versions_on_company_id ON public.route_list_versions USING btree (company_id);


--
-- Name: index_route_list_versions_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_list_versions_on_trip_id ON public.route_list_versions USING btree (trip_id);


--
-- Name: index_route_list_versions_on_trip_id_and_valid_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_list_versions_on_trip_id_and_valid_until ON public.route_list_versions USING btree (trip_id, valid_until);


--
-- Name: index_route_replacements_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_route_replacements_dates ON public.school_route_replacements USING btree (school_route_id, starts_on, ends_on);


--
-- Name: index_route_vehicle_changes_once; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_route_vehicle_changes_once ON public.school_route_vehicle_changes USING btree (school_route_id, effective_from);


--
-- Name: index_routing_runs_on_school_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_routing_runs_on_school_id_and_created_at ON public.routing_runs USING btree (school_id, created_at);


--
-- Name: index_routing_runs_on_target_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_routing_runs_on_target_plan_id ON public.routing_runs USING btree (target_plan_id);


--
-- Name: index_routing_settings_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_routing_settings_on_company_id ON public.routing_settings USING btree (company_id);


--
-- Name: index_school_attendant_policies_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_attendant_policies_on_school_id ON public.school_attendant_policies USING btree (school_id);


--
-- Name: index_school_bill_lines_on_school_bill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_bill_lines_on_school_bill_id ON public.school_bill_lines USING btree (school_bill_id);


--
-- Name: index_school_bills_on_bus_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_bills_on_bus_request_id ON public.school_bills USING btree (bus_request_id);


--
-- Name: index_school_bills_on_company_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_bills_on_company_id_and_number ON public.school_bills USING btree (company_id, number);


--
-- Name: index_school_bills_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_bills_on_family_id ON public.school_bills USING btree (family_id);


--
-- Name: index_school_bills_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_bills_on_school_id ON public.school_bills USING btree (school_id);


--
-- Name: index_school_bus_size_rates_on_school_id_and_bus_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_bus_size_rates_on_school_id_and_bus_type ON public.school_bus_size_rates USING btree (school_id, bus_type);


--
-- Name: index_school_holidays_on_academic_year_id_and_starts_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_holidays_on_academic_year_id_and_starts_on ON public.school_holidays USING btree (academic_year_id, starts_on);


--
-- Name: index_school_levels_unique_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_levels_unique_name ON public.school_levels USING btree (school_id, lower((name)::text));


--
-- Name: index_school_operator_pays_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_operator_pays_on_school_id ON public.school_operator_pays USING btree (school_id);


--
-- Name: index_school_payment_methods_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_payment_methods_on_school_id ON public.school_payment_methods USING btree (school_id);


--
-- Name: index_school_plan_changes_on_bus_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_plan_changes_on_bus_request_id ON public.school_plan_changes USING btree (bus_request_id);


--
-- Name: index_school_plan_changes_on_school_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_plan_changes_on_school_plan_id ON public.school_plan_changes USING btree (school_plan_id);


--
-- Name: index_school_plans_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_plans_on_company_id ON public.school_plans USING btree (company_id);


--
-- Name: index_school_plans_on_routing_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_plans_on_routing_run_id ON public.school_plans USING btree (routing_run_id);


--
-- Name: index_school_plans_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_plans_on_school_id ON public.school_plans USING btree (school_id);


--
-- Name: index_school_policy_versions_on_school_id_and_effective_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_policy_versions_on_school_id_and_effective_on ON public.school_policy_versions USING btree (school_id, effective_on);


--
-- Name: index_school_policy_versions_on_school_id_and_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_policy_versions_on_school_id_and_version ON public.school_policy_versions USING btree (school_id, version);


--
-- Name: index_school_registrations_on_academic_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_registrations_on_academic_year_id ON public.school_registrations USING btree (academic_year_id);


--
-- Name: index_school_riders_manual_rid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_riders_manual_rid ON public.school_riders USING btree (school_id, rid) WHERE (rider_dataset_id IS NULL);


--
-- Name: index_school_riders_on_postal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_riders_on_postal ON public.school_riders USING btree (postal);


--
-- Name: index_school_riders_on_rider_dataset_id_and_rid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_riders_on_rider_dataset_id_and_rid ON public.school_riders USING btree (rider_dataset_id, rid) WHERE (rider_dataset_id IS NOT NULL);


--
-- Name: index_school_riders_on_school_id_and_rider_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_riders_on_school_id_and_rider_dataset_id ON public.school_riders USING btree (school_id, rider_dataset_id);


--
-- Name: index_school_route_labels_on_school_id_and_session; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_route_labels_on_school_id_and_session ON public.school_route_labels USING btree (school_id, session);


--
-- Name: index_school_route_replacements_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_replacements_on_company_id ON public.school_route_replacements USING btree (company_id);


--
-- Name: index_school_route_replacements_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_replacements_on_created_by_id ON public.school_route_replacements USING btree (created_by_id);


--
-- Name: index_school_route_replacements_on_school_route_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_replacements_on_school_route_id ON public.school_route_replacements USING btree (school_route_id);


--
-- Name: index_school_route_replacements_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_replacements_on_vehicle_id ON public.school_route_replacements USING btree (vehicle_id);


--
-- Name: index_school_route_riders_on_rid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_riders_on_rid ON public.school_route_riders USING btree (rid);


--
-- Name: index_school_route_riders_on_school_route_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_riders_on_school_route_id ON public.school_route_riders USING btree (school_route_id);


--
-- Name: index_school_route_riders_on_school_route_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_riders_on_school_route_stop_id ON public.school_route_riders USING btree (school_route_stop_id);


--
-- Name: index_school_route_stops_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_stops_on_company_id ON public.school_route_stops USING btree (company_id);


--
-- Name: index_school_route_stops_on_school_route_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_stops_on_school_route_id ON public.school_route_stops USING btree (school_route_id);


--
-- Name: index_school_route_stops_on_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_stops_on_stop_id ON public.school_route_stops USING btree (stop_id);


--
-- Name: index_school_route_stops_on_stop_point_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_stops_on_stop_point_id ON public.school_route_stops USING btree (stop_point_id);


--
-- Name: index_school_route_vehicle_changes_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_vehicle_changes_on_company_id ON public.school_route_vehicle_changes USING btree (company_id);


--
-- Name: index_school_route_vehicle_changes_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_vehicle_changes_on_created_by_id ON public.school_route_vehicle_changes USING btree (created_by_id);


--
-- Name: index_school_route_vehicle_changes_on_school_route_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_vehicle_changes_on_school_route_id ON public.school_route_vehicle_changes USING btree (school_route_id);


--
-- Name: index_school_route_vehicle_changes_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_route_vehicle_changes_on_vehicle_id ON public.school_route_vehicle_changes USING btree (vehicle_id);


--
-- Name: index_school_routes_on_attendant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_routes_on_attendant_id ON public.school_routes USING btree (attendant_id);


--
-- Name: index_school_routes_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_routes_on_company_id ON public.school_routes USING btree (company_id);


--
-- Name: index_school_routes_on_school_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_routes_on_school_plan_id ON public.school_routes USING btree (school_plan_id);


--
-- Name: index_school_routes_on_school_plan_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_routes_on_school_plan_id_and_number ON public.school_routes USING btree (school_plan_id, number);


--
-- Name: index_school_special_days_on_academic_year_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_special_days_on_academic_year_id_and_date ON public.school_special_days USING btree (academic_year_id, date);


--
-- Name: index_school_stops_on_postal_codes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_stops_on_postal_codes ON public.school_stops USING gin (postal_codes);


--
-- Name: index_school_stops_on_school_id_and_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_stops_on_school_id_and_stop_id ON public.school_stops USING btree (school_id, stop_id);


--
-- Name: index_school_stops_on_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_school_stops_on_stop_id ON public.school_stops USING btree (stop_id);


--
-- Name: index_schools_on_calendar_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_schools_on_calendar_id ON public.schools USING btree (calendar_id);


--
-- Name: index_schools_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_schools_on_client_id ON public.schools USING btree (client_id) WHERE (client_id IS NOT NULL);


--
-- Name: index_schools_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_schools_on_company_id ON public.schools USING btree (company_id);


--
-- Name: index_schools_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_schools_on_company_id_and_name ON public.schools USING btree (company_id, name);


--
-- Name: index_setup_locks_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_setup_locks_unique ON public.setup_locks USING btree (school_id, COALESCE(academic_year_id, (0)::bigint), section);


--
-- Name: index_stop_photo_requests_on_stop_point_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stop_photo_requests_on_stop_point_id_and_status ON public.stop_photo_requests USING btree (stop_point_id, status);


--
-- Name: index_stop_photo_submissions_on_stop_photo_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stop_photo_submissions_on_stop_photo_request_id ON public.stop_photo_submissions USING btree (stop_photo_request_id);


--
-- Name: index_stop_points_on_stop_id_and_suffix; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stop_points_on_stop_id_and_suffix ON public.stop_points USING btree (stop_id, suffix);


--
-- Name: index_stops_on_company_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stops_on_company_id_and_code ON public.stops USING btree (company_id, code);


--
-- Name: index_stops_on_company_id_and_library_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stops_on_company_id_and_library_status ON public.stops USING btree (company_id, library_status);


--
-- Name: index_student_attendances_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_student_attendances_on_company_id ON public.student_attendances USING btree (company_id);


--
-- Name: index_student_attendances_on_recorded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_student_attendances_on_recorded_by_id ON public.student_attendances USING btree (recorded_by_id);


--
-- Name: index_student_attendances_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_student_attendances_on_trip_id ON public.student_attendances USING btree (trip_id);


--
-- Name: index_student_attendances_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_student_attendances_on_trip_run_id ON public.student_attendances USING btree (trip_run_id);


--
-- Name: index_student_attendances_once; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_student_attendances_once ON public.student_attendances USING btree (trip_id, run_date, trip_run_id, slot_no, student_key);


--
-- Name: index_tracking_devices_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracking_devices_on_company_id ON public.tracking_devices USING btree (company_id);


--
-- Name: index_tracking_devices_on_company_id_and_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tracking_devices_on_company_id_and_identifier ON public.tracking_devices USING btree (company_id, identifier) WHERE (identifier IS NOT NULL);


--
-- Name: index_tracking_devices_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracking_devices_on_vehicle_id ON public.tracking_devices USING btree (vehicle_id);


--
-- Name: index_tracking_links_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracking_links_on_company_id ON public.tracking_links USING btree (company_id);


--
-- Name: index_tracking_links_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracking_links_on_created_by_id ON public.tracking_links USING btree (created_by_id);


--
-- Name: index_tracking_links_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tracking_links_on_token ON public.tracking_links USING btree (token);


--
-- Name: index_tracking_links_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracking_links_on_trip_id ON public.tracking_links USING btree (trip_id);


--
-- Name: index_tracking_links_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracking_links_on_trip_run_id ON public.tracking_links USING btree (trip_run_id);


--
-- Name: index_tracking_links_one_per_run; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tracking_links_one_per_run ON public.tracking_links USING btree (trip_id, run_date, trip_run_id, slot_no);


--
-- Name: index_trip_assignment_slots_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignment_slots_on_company_id ON public.trip_assignment_slots USING btree (company_id);


--
-- Name: index_trip_assignment_slots_on_trip_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignment_slots_on_trip_assignment_id ON public.trip_assignment_slots USING btree (trip_assignment_id);


--
-- Name: index_trip_assignment_slots_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignment_slots_on_trip_run_id ON public.trip_assignment_slots USING btree (trip_run_id);


--
-- Name: index_trip_assignment_slots_once; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_assignment_slots_once ON public.trip_assignment_slots USING btree (trip_assignment_id, trip_run_id, slot_no);


--
-- Name: index_trip_assignments_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignments_on_company_id ON public.trip_assignments USING btree (company_id);


--
-- Name: index_trip_assignments_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignments_on_created_by_id ON public.trip_assignments USING btree (created_by_id);


--
-- Name: index_trip_assignments_on_operator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignments_on_operator_id ON public.trip_assignments USING btree (operator_id);


--
-- Name: index_trip_assignments_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignments_on_trip_id ON public.trip_assignments USING btree (trip_id);


--
-- Name: index_trip_assignments_on_trip_id_and_effective_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignments_on_trip_id_and_effective_from ON public.trip_assignments USING btree (trip_id, effective_from);


--
-- Name: index_trip_assignments_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_assignments_on_vehicle_id ON public.trip_assignments USING btree (vehicle_id);


--
-- Name: index_trip_attachments_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_attachments_on_company_id ON public.trip_attachments USING btree (company_id);


--
-- Name: index_trip_attachments_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_attachments_on_trip_id ON public.trip_attachments USING btree (trip_id);


--
-- Name: index_trip_attachments_on_uploaded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_attachments_on_uploaded_by_id ON public.trip_attachments USING btree (uploaded_by_id);


--
-- Name: index_trip_occurrences_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_occurrences_identity ON ONLY public.trip_occurrences USING btree (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part);


--
-- Name: index_trip_occurrences_on_company_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_on_company_date ON ONLY public.trip_occurrences USING btree (company_id, date);


--
-- Name: index_trip_occurrences_on_driver_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_on_driver_date ON ONLY public.trip_occurrences USING btree (driver_id, date) WHERE (driver_id IS NOT NULL);


--
-- Name: index_trip_occurrences_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_on_id ON ONLY public.trip_occurrences USING btree (id);


--
-- Name: index_trip_occurrences_on_operator_driver_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_on_operator_driver_date ON ONLY public.trip_occurrences USING btree (operator_driver_id, date) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: index_trip_occurrences_on_route_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_on_route_date ON ONLY public.trip_occurrences USING btree (school_route_id, date) WHERE (school_route_id IS NOT NULL);


--
-- Name: index_trip_occurrences_on_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_on_starts_at ON ONLY public.trip_occurrences USING btree (company_id, starts_at);


--
-- Name: index_trip_occurrences_on_trip_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_on_trip_date ON ONLY public.trip_occurrences USING btree (trip_id, date);


--
-- Name: index_trip_occurrences_on_vehicle_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_on_vehicle_date ON ONLY public.trip_occurrences USING btree (vehicle_id, date);


--
-- Name: index_trip_occurrences_unassigned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_occurrences_unassigned ON ONLY public.trip_occurrences USING btree (company_id, date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text));


--
-- Name: index_trip_price_cells_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_price_cells_on_company_id ON public.trip_price_cells USING btree (company_id);


--
-- Name: index_trip_price_cells_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_price_cells_on_trip_id ON public.trip_price_cells USING btree (trip_id);


--
-- Name: index_trip_price_cells_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_price_cells_on_trip_run_id ON public.trip_price_cells USING btree (trip_run_id);


--
-- Name: index_trip_price_cells_one_per_cell; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_price_cells_one_per_cell ON public.trip_price_cells USING btree (trip_id, COALESCE(direction, 0), COALESCE(trip_run_id, (0)::bigint), COALESCE(slot_no, 0));


--
-- Name: index_trip_route_vias_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_route_vias_on_company_id ON public.trip_route_vias USING btree (company_id);


--
-- Name: index_trip_route_vias_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_route_vias_on_trip_id ON public.trip_route_vias USING btree (trip_id);


--
-- Name: index_trip_run_groups_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_groups_on_company_id ON public.trip_run_groups USING btree (company_id);


--
-- Name: index_trip_run_groups_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_groups_on_trip_id ON public.trip_run_groups USING btree (trip_id);


--
-- Name: index_trip_run_slots_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_slots_on_company_id ON public.trip_run_slots USING btree (company_id);


--
-- Name: index_trip_run_slots_on_trip_run_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_slots_on_trip_run_group_id ON public.trip_run_slots USING btree (trip_run_group_id);


--
-- Name: index_trip_run_slots_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_slots_on_trip_run_id ON public.trip_run_slots USING btree (trip_run_id);


--
-- Name: index_trip_run_slots_on_trip_run_id_and_slot_no; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_run_slots_on_trip_run_id_and_slot_no ON public.trip_run_slots USING btree (trip_run_id, slot_no);


--
-- Name: index_trip_run_slots_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_slots_on_vehicle_id ON public.trip_run_slots USING btree (vehicle_id);


--
-- Name: index_trip_run_times_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_times_on_company_id ON public.trip_run_times USING btree (company_id);


--
-- Name: index_trip_run_times_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_times_on_trip_run_id ON public.trip_run_times USING btree (trip_run_id);


--
-- Name: index_trip_run_times_on_trip_run_id_and_trip_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_run_times_on_trip_run_id_and_trip_stop_id ON public.trip_run_times USING btree (trip_run_id, trip_stop_id);


--
-- Name: index_trip_run_times_on_trip_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_run_times_on_trip_stop_id ON public.trip_run_times USING btree (trip_stop_id);


--
-- Name: index_trip_runs_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_runs_on_company_id ON public.trip_runs USING btree (company_id);


--
-- Name: index_trip_runs_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_runs_on_trip_id ON public.trip_runs USING btree (trip_id);


--
-- Name: index_trip_standby_photos_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_standby_photos_on_company_id ON public.trip_standby_photos USING btree (company_id);


--
-- Name: index_trip_standby_photos_on_trip_standby_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_standby_photos_on_trip_standby_id ON public.trip_standby_photos USING btree (trip_standby_id);


--
-- Name: index_trip_standbys_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_standbys_on_company_id ON public.trip_standbys USING btree (company_id);


--
-- Name: index_trip_standbys_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_standbys_on_trip_id ON public.trip_standbys USING btree (trip_id);


--
-- Name: index_trip_stop_photos_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_photos_on_company_id ON public.trip_stop_photos USING btree (company_id);


--
-- Name: index_trip_stop_photos_on_trip_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_photos_on_trip_stop_id ON public.trip_stop_photos USING btree (trip_stop_id);


--
-- Name: index_trip_stop_students_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_students_on_company_id ON public.trip_stop_students USING btree (company_id);


--
-- Name: index_trip_stop_students_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_students_on_key ON public.trip_stop_students USING btree (key);


--
-- Name: index_trip_stop_students_on_trip_stop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stop_students_on_trip_stop_id ON public.trip_stop_students USING btree (trip_stop_id);


--
-- Name: index_trip_stops_on_client_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_client_site_id ON public.trip_stops USING btree (client_site_id);


--
-- Name: index_trip_stops_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_company_id ON public.trip_stops USING btree (company_id);


--
-- Name: index_trip_stops_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_stops_on_trip_id ON public.trip_stops USING btree (trip_id);


--
-- Name: index_trip_time_changes_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_time_changes_on_company_id ON public.trip_time_changes USING btree (company_id);


--
-- Name: index_trip_time_changes_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_time_changes_on_created_by_id ON public.trip_time_changes USING btree (created_by_id);


--
-- Name: index_trip_time_changes_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_time_changes_on_trip_id ON public.trip_time_changes USING btree (trip_id);


--
-- Name: index_trip_time_changes_on_trip_id_and_effective_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_time_changes_on_trip_id_and_effective_from ON public.trip_time_changes USING btree (trip_id, effective_from);


--
-- Name: index_trip_time_changes_on_trip_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_time_changes_on_trip_run_id ON public.trip_time_changes USING btree (trip_run_id);


--
-- Name: index_trip_vehicle_requirements_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_vehicle_requirements_on_company_id ON public.trip_vehicle_requirements USING btree (company_id);


--
-- Name: index_trip_vehicle_requirements_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_vehicle_requirements_on_trip_id ON public.trip_vehicle_requirements USING btree (trip_id);


--
-- Name: index_trip_vehicle_requirements_on_trip_id_and_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trip_vehicle_requirements_on_trip_id_and_vehicle_type_id ON public.trip_vehicle_requirements USING btree (trip_id, vehicle_type_id);


--
-- Name: index_trip_vehicle_requirements_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_vehicle_requirements_on_vehicle_type_id ON public.trip_vehicle_requirements USING btree (vehicle_type_id);


--
-- Name: index_trip_vehicle_slots_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_vehicle_slots_on_company_id ON public.trip_vehicle_slots USING btree (company_id);


--
-- Name: index_trip_vehicle_slots_on_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_vehicle_slots_on_trip_id ON public.trip_vehicle_slots USING btree (trip_id);


--
-- Name: index_trip_vehicle_slots_on_vehicle; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_vehicle_slots_on_vehicle ON public.trip_vehicle_slots USING btree (vehicle_id);


--
-- Name: index_trip_vehicle_slots_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trip_vehicle_slots_on_vehicle_id ON public.trip_vehicle_slots USING btree (vehicle_id);


--
-- Name: index_trips_on_booking_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_booking_trip_id ON public.trips USING btree (booking_trip_id);


--
-- Name: index_trips_on_calendar_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_calendar_id ON public.trips USING btree (calendar_id);


--
-- Name: index_trips_on_client_end_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_client_end_customer_id ON public.trips USING btree (client_end_customer_id);


--
-- Name: index_trips_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_client_id ON public.trips USING btree (client_id);


--
-- Name: index_trips_on_client_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_client_site_id ON public.trips USING btree (client_site_id);


--
-- Name: index_trips_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_company_id ON public.trips USING btree (company_id);


--
-- Name: index_trips_on_company_id_and_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_company_id_and_kind ON public.trips USING btree (company_id, kind);


--
-- Name: index_trips_on_company_id_and_starts_on_and_ends_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_company_id_and_starts_on_and_ends_on ON public.trips USING btree (company_id, starts_on, ends_on);


--
-- Name: index_trips_on_company_id_and_trip_no; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trips_on_company_id_and_trip_no ON public.trips USING btree (company_id, trip_no);


--
-- Name: index_trips_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_created_by_id ON public.trips USING btree (created_by_id);


--
-- Name: index_trips_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_discarded_at ON public.trips USING btree (discarded_at);


--
-- Name: index_trips_on_pair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_pair_id ON public.trips USING btree (pair_id);


--
-- Name: index_trips_on_route_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trips_on_route_tags ON public.trips USING gin (route_tags);


--
-- Name: index_ura_subzones_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ura_subzones_on_code ON public.ura_subzones USING btree (code);


--
-- Name: index_ura_subzones_on_min_lat_and_max_lat; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ura_subzones_on_min_lat_and_max_lat ON public.ura_subzones USING btree (min_lat, max_lat);


--
-- Name: index_user_notification_preferences_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notification_preferences_on_company_id ON public.user_notification_preferences USING btree (company_id);


--
-- Name: index_user_notification_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_notification_preferences_on_user_id ON public.user_notification_preferences USING btree (user_id);


--
-- Name: index_user_schools_on_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_schools_on_school_id ON public.user_schools USING btree (school_id);


--
-- Name: index_user_schools_on_user_id_and_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_schools_on_user_id_and_school_id ON public.user_schools USING btree (user_id, school_id);


--
-- Name: index_users_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_company_id ON public.users USING btree (company_id);


--
-- Name: index_users_on_company_id_and_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_company_id_and_discarded_at ON public.users USING btree (company_id, discarded_at);


--
-- Name: index_users_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_created_by_id ON public.users USING btree (created_by_id);


--
-- Name: index_users_on_live_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_live_email ON public.users USING btree (email) WHERE (discarded_at IS NULL);


--
-- Name: index_users_on_permissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_permissions ON public.users USING gin (permissions);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_vehicle_cost_spike_acks_on_checked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_cost_spike_acks_on_checked_by_id ON public.vehicle_cost_spike_acks USING btree (checked_by_id);


--
-- Name: index_vehicle_cost_spike_acks_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_cost_spike_acks_unique ON public.vehicle_cost_spike_acks USING btree (vehicle_id, category, month);


--
-- Name: index_vehicle_driver_schedules_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_driver_schedules_on_company_id ON public.vehicle_driver_schedules USING btree (company_id);


--
-- Name: index_vehicle_driver_schedules_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_driver_schedules_on_created_by_id ON public.vehicle_driver_schedules USING btree (created_by_id);


--
-- Name: index_vehicle_driver_schedules_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_driver_schedules_on_driver_id ON public.vehicle_driver_schedules USING btree (driver_id);


--
-- Name: index_vehicle_driver_schedules_on_driver_id_and_starts_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_driver_schedules_on_driver_id_and_starts_on ON public.vehicle_driver_schedules USING btree (driver_id, starts_on);


--
-- Name: index_vehicle_driver_schedules_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_driver_schedules_on_vehicle_id ON public.vehicle_driver_schedules USING btree (vehicle_id);


--
-- Name: index_vehicle_driver_schedules_on_vehicle_id_and_starts_on; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_driver_schedules_on_vehicle_id_and_starts_on ON public.vehicle_driver_schedules USING btree (vehicle_id, starts_on);


--
-- Name: index_vehicle_finance_entries_on_company_id_and_entry_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_finance_entries_on_company_id_and_entry_on ON public.vehicle_finance_entries USING btree (company_id, entry_on);


--
-- Name: index_vehicle_finance_entries_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_finance_entries_on_created_by_id ON public.vehicle_finance_entries USING btree (created_by_id);


--
-- Name: index_vehicle_finance_entries_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_finance_entries_on_vehicle_id ON public.vehicle_finance_entries USING btree (vehicle_id);


--
-- Name: index_vehicle_financials_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_financials_on_company_id ON public.vehicle_financials USING btree (company_id);


--
-- Name: index_vehicle_financials_on_document_read_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_financials_on_document_read_id ON public.vehicle_financials USING btree (document_read_id);


--
-- Name: index_vehicle_financials_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_financials_on_updated_by_id ON public.vehicle_financials USING btree (updated_by_id);


--
-- Name: index_vehicle_financials_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_financials_on_vehicle_id ON public.vehicle_financials USING btree (vehicle_id);


--
-- Name: index_vehicle_insurance_documents_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_insurance_documents_on_company_id ON public.vehicle_insurance_documents USING btree (company_id);


--
-- Name: index_vehicle_insurance_policies_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_insurance_policies_on_company_id ON public.vehicle_insurance_policies USING btree (company_id);


--
-- Name: index_vehicle_insurance_policies_on_company_id_and_ends_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_insurance_policies_on_company_id_and_ends_on ON public.vehicle_insurance_policies USING btree (company_id, ends_on);


--
-- Name: index_vehicle_insurance_policies_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_insurance_policies_on_vehicle_id ON public.vehicle_insurance_policies USING btree (vehicle_id);


--
-- Name: index_vehicle_insurance_policies_one_current; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_insurance_policies_one_current ON public.vehicle_insurance_policies USING btree (vehicle_id) WHERE current;


--
-- Name: index_vehicle_live_positions_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_live_positions_on_company_id ON public.vehicle_live_positions USING btree (company_id);


--
-- Name: index_vehicle_live_positions_on_tracking_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_live_positions_on_tracking_device_id ON public.vehicle_live_positions USING btree (tracking_device_id);


--
-- Name: index_vehicle_live_positions_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_live_positions_on_vehicle_id ON public.vehicle_live_positions USING btree (vehicle_id);


--
-- Name: index_vehicle_loan_payments_on_recorded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_loan_payments_on_recorded_by_id ON public.vehicle_loan_payments USING btree (recorded_by_id);


--
-- Name: index_vehicle_loan_payments_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_loan_payments_unique ON public.vehicle_loan_payments USING btree (vehicle_financial_id, instalment_no);


--
-- Name: index_vehicle_log_cards_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_log_cards_on_company_id ON public.vehicle_log_cards USING btree (company_id);


--
-- Name: index_vehicle_log_cards_on_uploaded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_log_cards_on_uploaded_by_id ON public.vehicle_log_cards USING btree (uploaded_by_id);


--
-- Name: index_vehicle_log_cards_on_vehicle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_log_cards_on_vehicle_id ON public.vehicle_log_cards USING btree (vehicle_id);


--
-- Name: index_vehicle_log_cards_one_current; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_log_cards_one_current ON public.vehicle_log_cards USING btree (vehicle_id) WHERE current;


--
-- Name: index_vehicle_teams_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_teams_on_company_id ON public.vehicle_teams USING btree (company_id);


--
-- Name: index_vehicle_teams_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_teams_on_company_id_and_name ON public.vehicle_teams USING btree (company_id, name);


--
-- Name: index_vehicle_type_requests_on_company_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_type_requests_on_company_id_and_created_at ON public.vehicle_type_requests USING btree (company_id, created_at);


--
-- Name: index_vehicle_type_requests_on_decided_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_type_requests_on_decided_by_id ON public.vehicle_type_requests USING btree (decided_by_id);


--
-- Name: index_vehicle_type_requests_on_requested_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_type_requests_on_requested_by_id ON public.vehicle_type_requests USING btree (requested_by_id);


--
-- Name: index_vehicle_type_requests_on_status_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_type_requests_on_status_and_created_at ON public.vehicle_type_requests USING btree (status, created_at);


--
-- Name: index_vehicle_type_requests_on_vehicle_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_type_requests_on_vehicle_type_id ON public.vehicle_type_requests USING btree (vehicle_type_id);


--
-- Name: index_vehicle_types_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_types_on_key ON public.vehicle_types USING btree (key);


--
-- Name: index_vehicles_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicles_on_company_id ON public.vehicles USING btree (company_id);


--
-- Name: index_vehicles_on_company_id_and_plate; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicles_on_company_id_and_plate ON public.vehicles USING btree (company_id, plate) WHERE (discarded_at IS NULL);


--
-- Name: index_vehicles_on_company_id_and_seats; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicles_on_company_id_and_seats ON public.vehicles USING btree (company_id, seats);


--
-- Name: index_vehicles_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicles_on_discarded_at ON public.vehicles USING btree (discarded_at);


--
-- Name: index_vehicles_on_operator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicles_on_operator_id ON public.vehicles USING btree (operator_id);


--
-- Name: index_vehicles_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicles_on_tags ON public.vehicles USING gin (tags);


--
-- Name: index_vehicles_on_vehicle_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicles_on_vehicle_team_id ON public.vehicles USING btree (vehicle_team_id);


--
-- Name: index_workshops_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workshops_on_company_id ON public.workshops USING btree (company_id);


--
-- Name: index_workshops_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_workshops_on_company_id_and_name ON public.workshops USING btree (company_id, name);


--
-- Name: occurrence_positions_y2026m09_occurrence_id_occurrence_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2026m09_occurrence_id_occurrence_date_idx ON public.occurrence_positions_y2026m09 USING btree (occurrence_id, occurrence_date, recorded_at);


--
-- Name: occurrence_positions_y2026m09_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2026m09_recorded_at_idx ON public.occurrence_positions_y2026m09 USING brin (recorded_at);


--
-- Name: occurrence_positions_y2026m10_occurrence_id_occurrence_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2026m10_occurrence_id_occurrence_date_idx ON public.occurrence_positions_y2026m10 USING btree (occurrence_id, occurrence_date, recorded_at);


--
-- Name: occurrence_positions_y2026m10_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2026m10_recorded_at_idx ON public.occurrence_positions_y2026m10 USING brin (recorded_at);


--
-- Name: occurrence_positions_y2026m11_occurrence_id_occurrence_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2026m11_occurrence_id_occurrence_date_idx ON public.occurrence_positions_y2026m11 USING btree (occurrence_id, occurrence_date, recorded_at);


--
-- Name: occurrence_positions_y2026m11_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2026m11_recorded_at_idx ON public.occurrence_positions_y2026m11 USING brin (recorded_at);


--
-- Name: occurrence_positions_y2026m12_occurrence_id_occurrence_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2026m12_occurrence_id_occurrence_date_idx ON public.occurrence_positions_y2026m12 USING btree (occurrence_id, occurrence_date, recorded_at);


--
-- Name: occurrence_positions_y2026m12_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2026m12_recorded_at_idx ON public.occurrence_positions_y2026m12 USING brin (recorded_at);


--
-- Name: occurrence_positions_y2027m01_occurrence_id_occurrence_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2027m01_occurrence_id_occurrence_date_idx ON public.occurrence_positions_y2027m01 USING btree (occurrence_id, occurrence_date, recorded_at);


--
-- Name: occurrence_positions_y2027m01_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2027m01_recorded_at_idx ON public.occurrence_positions_y2027m01 USING brin (recorded_at);


--
-- Name: occurrence_positions_y2027m02_occurrence_id_occurrence_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2027m02_occurrence_id_occurrence_date_idx ON public.occurrence_positions_y2027m02 USING btree (occurrence_id, occurrence_date, recorded_at);


--
-- Name: occurrence_positions_y2027m02_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2027m02_recorded_at_idx ON public.occurrence_positions_y2027m02 USING brin (recorded_at);


--
-- Name: occurrence_positions_y2027m03_occurrence_id_occurrence_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2027m03_occurrence_id_occurrence_date_idx ON public.occurrence_positions_y2027m03 USING btree (occurrence_id, occurrence_date, recorded_at);


--
-- Name: occurrence_positions_y2027m03_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX occurrence_positions_y2027m03_recorded_at_idx ON public.occurrence_positions_y2027m03 USING brin (recorded_at);


--
-- Name: trip_occurrences_y2026m09_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trip_occurrences_y2026m09_coalesce_coalesce1_date_coalesce2_idx ON public.trip_occurrences_y2026m09 USING btree (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part);


--
-- Name: trip_occurrences_y2026m09_company_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_company_id_date_idx ON public.trip_occurrences_y2026m09 USING btree (company_id, date);


--
-- Name: trip_occurrences_y2026m09_company_id_date_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_company_id_date_idx1 ON public.trip_occurrences_y2026m09 USING btree (company_id, date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text));


--
-- Name: trip_occurrences_y2026m09_company_id_starts_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_company_id_starts_at_idx ON public.trip_occurrences_y2026m09 USING btree (company_id, starts_at);


--
-- Name: trip_occurrences_y2026m09_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_driver_id_date_idx ON public.trip_occurrences_y2026m09 USING btree (driver_id, date) WHERE (driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m09_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_id_idx ON public.trip_occurrences_y2026m09 USING btree (id);


--
-- Name: trip_occurrences_y2026m09_operator_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_operator_driver_id_date_idx ON public.trip_occurrences_y2026m09 USING btree (operator_driver_id, date) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m09_school_route_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_school_route_id_date_idx ON public.trip_occurrences_y2026m09 USING btree (school_route_id, date) WHERE (school_route_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m09_trip_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_trip_id_date_idx ON public.trip_occurrences_y2026m09 USING btree (trip_id, date);


--
-- Name: trip_occurrences_y2026m09_vehicle_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m09_vehicle_id_date_idx ON public.trip_occurrences_y2026m09 USING btree (vehicle_id, date);


--
-- Name: trip_occurrences_y2026m10_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trip_occurrences_y2026m10_coalesce_coalesce1_date_coalesce2_idx ON public.trip_occurrences_y2026m10 USING btree (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part);


--
-- Name: trip_occurrences_y2026m10_company_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_company_id_date_idx ON public.trip_occurrences_y2026m10 USING btree (company_id, date);


--
-- Name: trip_occurrences_y2026m10_company_id_date_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_company_id_date_idx1 ON public.trip_occurrences_y2026m10 USING btree (company_id, date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text));


--
-- Name: trip_occurrences_y2026m10_company_id_starts_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_company_id_starts_at_idx ON public.trip_occurrences_y2026m10 USING btree (company_id, starts_at);


--
-- Name: trip_occurrences_y2026m10_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_driver_id_date_idx ON public.trip_occurrences_y2026m10 USING btree (driver_id, date) WHERE (driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m10_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_id_idx ON public.trip_occurrences_y2026m10 USING btree (id);


--
-- Name: trip_occurrences_y2026m10_operator_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_operator_driver_id_date_idx ON public.trip_occurrences_y2026m10 USING btree (operator_driver_id, date) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m10_school_route_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_school_route_id_date_idx ON public.trip_occurrences_y2026m10 USING btree (school_route_id, date) WHERE (school_route_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m10_trip_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_trip_id_date_idx ON public.trip_occurrences_y2026m10 USING btree (trip_id, date);


--
-- Name: trip_occurrences_y2026m10_vehicle_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m10_vehicle_id_date_idx ON public.trip_occurrences_y2026m10 USING btree (vehicle_id, date);


--
-- Name: trip_occurrences_y2026m11_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trip_occurrences_y2026m11_coalesce_coalesce1_date_coalesce2_idx ON public.trip_occurrences_y2026m11 USING btree (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part);


--
-- Name: trip_occurrences_y2026m11_company_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_company_id_date_idx ON public.trip_occurrences_y2026m11 USING btree (company_id, date);


--
-- Name: trip_occurrences_y2026m11_company_id_date_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_company_id_date_idx1 ON public.trip_occurrences_y2026m11 USING btree (company_id, date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text));


--
-- Name: trip_occurrences_y2026m11_company_id_starts_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_company_id_starts_at_idx ON public.trip_occurrences_y2026m11 USING btree (company_id, starts_at);


--
-- Name: trip_occurrences_y2026m11_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_driver_id_date_idx ON public.trip_occurrences_y2026m11 USING btree (driver_id, date) WHERE (driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m11_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_id_idx ON public.trip_occurrences_y2026m11 USING btree (id);


--
-- Name: trip_occurrences_y2026m11_operator_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_operator_driver_id_date_idx ON public.trip_occurrences_y2026m11 USING btree (operator_driver_id, date) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m11_school_route_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_school_route_id_date_idx ON public.trip_occurrences_y2026m11 USING btree (school_route_id, date) WHERE (school_route_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m11_trip_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_trip_id_date_idx ON public.trip_occurrences_y2026m11 USING btree (trip_id, date);


--
-- Name: trip_occurrences_y2026m11_vehicle_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m11_vehicle_id_date_idx ON public.trip_occurrences_y2026m11 USING btree (vehicle_id, date);


--
-- Name: trip_occurrences_y2026m12_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trip_occurrences_y2026m12_coalesce_coalesce1_date_coalesce2_idx ON public.trip_occurrences_y2026m12 USING btree (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part);


--
-- Name: trip_occurrences_y2026m12_company_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_company_id_date_idx ON public.trip_occurrences_y2026m12 USING btree (company_id, date);


--
-- Name: trip_occurrences_y2026m12_company_id_date_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_company_id_date_idx1 ON public.trip_occurrences_y2026m12 USING btree (company_id, date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text));


--
-- Name: trip_occurrences_y2026m12_company_id_starts_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_company_id_starts_at_idx ON public.trip_occurrences_y2026m12 USING btree (company_id, starts_at);


--
-- Name: trip_occurrences_y2026m12_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_driver_id_date_idx ON public.trip_occurrences_y2026m12 USING btree (driver_id, date) WHERE (driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m12_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_id_idx ON public.trip_occurrences_y2026m12 USING btree (id);


--
-- Name: trip_occurrences_y2026m12_operator_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_operator_driver_id_date_idx ON public.trip_occurrences_y2026m12 USING btree (operator_driver_id, date) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m12_school_route_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_school_route_id_date_idx ON public.trip_occurrences_y2026m12 USING btree (school_route_id, date) WHERE (school_route_id IS NOT NULL);


--
-- Name: trip_occurrences_y2026m12_trip_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_trip_id_date_idx ON public.trip_occurrences_y2026m12 USING btree (trip_id, date);


--
-- Name: trip_occurrences_y2026m12_vehicle_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2026m12_vehicle_id_date_idx ON public.trip_occurrences_y2026m12 USING btree (vehicle_id, date);


--
-- Name: trip_occurrences_y2027m01_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trip_occurrences_y2027m01_coalesce_coalesce1_date_coalesce2_idx ON public.trip_occurrences_y2027m01 USING btree (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part);


--
-- Name: trip_occurrences_y2027m01_company_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_company_id_date_idx ON public.trip_occurrences_y2027m01 USING btree (company_id, date);


--
-- Name: trip_occurrences_y2027m01_company_id_date_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_company_id_date_idx1 ON public.trip_occurrences_y2027m01 USING btree (company_id, date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text));


--
-- Name: trip_occurrences_y2027m01_company_id_starts_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_company_id_starts_at_idx ON public.trip_occurrences_y2027m01 USING btree (company_id, starts_at);


--
-- Name: trip_occurrences_y2027m01_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_driver_id_date_idx ON public.trip_occurrences_y2027m01 USING btree (driver_id, date) WHERE (driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m01_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_id_idx ON public.trip_occurrences_y2027m01 USING btree (id);


--
-- Name: trip_occurrences_y2027m01_operator_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_operator_driver_id_date_idx ON public.trip_occurrences_y2027m01 USING btree (operator_driver_id, date) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m01_school_route_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_school_route_id_date_idx ON public.trip_occurrences_y2027m01 USING btree (school_route_id, date) WHERE (school_route_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m01_trip_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_trip_id_date_idx ON public.trip_occurrences_y2027m01 USING btree (trip_id, date);


--
-- Name: trip_occurrences_y2027m01_vehicle_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m01_vehicle_id_date_idx ON public.trip_occurrences_y2027m01 USING btree (vehicle_id, date);


--
-- Name: trip_occurrences_y2027m02_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trip_occurrences_y2027m02_coalesce_coalesce1_date_coalesce2_idx ON public.trip_occurrences_y2027m02 USING btree (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part);


--
-- Name: trip_occurrences_y2027m02_company_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_company_id_date_idx ON public.trip_occurrences_y2027m02 USING btree (company_id, date);


--
-- Name: trip_occurrences_y2027m02_company_id_date_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_company_id_date_idx1 ON public.trip_occurrences_y2027m02 USING btree (company_id, date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text));


--
-- Name: trip_occurrences_y2027m02_company_id_starts_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_company_id_starts_at_idx ON public.trip_occurrences_y2027m02 USING btree (company_id, starts_at);


--
-- Name: trip_occurrences_y2027m02_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_driver_id_date_idx ON public.trip_occurrences_y2027m02 USING btree (driver_id, date) WHERE (driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m02_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_id_idx ON public.trip_occurrences_y2027m02 USING btree (id);


--
-- Name: trip_occurrences_y2027m02_operator_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_operator_driver_id_date_idx ON public.trip_occurrences_y2027m02 USING btree (operator_driver_id, date) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m02_school_route_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_school_route_id_date_idx ON public.trip_occurrences_y2027m02 USING btree (school_route_id, date) WHERE (school_route_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m02_trip_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_trip_id_date_idx ON public.trip_occurrences_y2027m02 USING btree (trip_id, date);


--
-- Name: trip_occurrences_y2027m02_vehicle_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m02_vehicle_id_date_idx ON public.trip_occurrences_y2027m02 USING btree (vehicle_id, date);


--
-- Name: trip_occurrences_y2027m03_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trip_occurrences_y2027m03_coalesce_coalesce1_date_coalesce2_idx ON public.trip_occurrences_y2027m03 USING btree (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part);


--
-- Name: trip_occurrences_y2027m03_company_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_company_id_date_idx ON public.trip_occurrences_y2027m03 USING btree (company_id, date);


--
-- Name: trip_occurrences_y2027m03_company_id_date_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_company_id_date_idx1 ON public.trip_occurrences_y2027m03 USING btree (company_id, date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text));


--
-- Name: trip_occurrences_y2027m03_company_id_starts_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_company_id_starts_at_idx ON public.trip_occurrences_y2027m03 USING btree (company_id, starts_at);


--
-- Name: trip_occurrences_y2027m03_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_driver_id_date_idx ON public.trip_occurrences_y2027m03 USING btree (driver_id, date) WHERE (driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m03_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_id_idx ON public.trip_occurrences_y2027m03 USING btree (id);


--
-- Name: trip_occurrences_y2027m03_operator_driver_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_operator_driver_id_date_idx ON public.trip_occurrences_y2027m03 USING btree (operator_driver_id, date) WHERE (operator_driver_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m03_school_route_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_school_route_id_date_idx ON public.trip_occurrences_y2027m03 USING btree (school_route_id, date) WHERE (school_route_id IS NOT NULL);


--
-- Name: trip_occurrences_y2027m03_trip_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_trip_id_date_idx ON public.trip_occurrences_y2027m03 USING btree (trip_id, date);


--
-- Name: trip_occurrences_y2027m03_vehicle_id_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trip_occurrences_y2027m03_vehicle_id_date_idx ON public.trip_occurrences_y2027m03 USING btree (vehicle_id, date);


--
-- Name: user_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_index ON public.audits USING btree (user_id, user_type);


--
-- Name: occurrence_positions_y2026m09_occurrence_id_occurrence_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_run ATTACH PARTITION public.occurrence_positions_y2026m09_occurrence_id_occurrence_date_idx;


--
-- Name: occurrence_positions_y2026m09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.occurrence_positions_pkey ATTACH PARTITION public.occurrence_positions_y2026m09_pkey;


--
-- Name: occurrence_positions_y2026m09_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_recorded_at ATTACH PARTITION public.occurrence_positions_y2026m09_recorded_at_idx;


--
-- Name: occurrence_positions_y2026m10_occurrence_id_occurrence_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_run ATTACH PARTITION public.occurrence_positions_y2026m10_occurrence_id_occurrence_date_idx;


--
-- Name: occurrence_positions_y2026m10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.occurrence_positions_pkey ATTACH PARTITION public.occurrence_positions_y2026m10_pkey;


--
-- Name: occurrence_positions_y2026m10_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_recorded_at ATTACH PARTITION public.occurrence_positions_y2026m10_recorded_at_idx;


--
-- Name: occurrence_positions_y2026m11_occurrence_id_occurrence_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_run ATTACH PARTITION public.occurrence_positions_y2026m11_occurrence_id_occurrence_date_idx;


--
-- Name: occurrence_positions_y2026m11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.occurrence_positions_pkey ATTACH PARTITION public.occurrence_positions_y2026m11_pkey;


--
-- Name: occurrence_positions_y2026m11_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_recorded_at ATTACH PARTITION public.occurrence_positions_y2026m11_recorded_at_idx;


--
-- Name: occurrence_positions_y2026m12_occurrence_id_occurrence_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_run ATTACH PARTITION public.occurrence_positions_y2026m12_occurrence_id_occurrence_date_idx;


--
-- Name: occurrence_positions_y2026m12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.occurrence_positions_pkey ATTACH PARTITION public.occurrence_positions_y2026m12_pkey;


--
-- Name: occurrence_positions_y2026m12_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_recorded_at ATTACH PARTITION public.occurrence_positions_y2026m12_recorded_at_idx;


--
-- Name: occurrence_positions_y2027m01_occurrence_id_occurrence_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_run ATTACH PARTITION public.occurrence_positions_y2027m01_occurrence_id_occurrence_date_idx;


--
-- Name: occurrence_positions_y2027m01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.occurrence_positions_pkey ATTACH PARTITION public.occurrence_positions_y2027m01_pkey;


--
-- Name: occurrence_positions_y2027m01_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_recorded_at ATTACH PARTITION public.occurrence_positions_y2027m01_recorded_at_idx;


--
-- Name: occurrence_positions_y2027m02_occurrence_id_occurrence_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_run ATTACH PARTITION public.occurrence_positions_y2027m02_occurrence_id_occurrence_date_idx;


--
-- Name: occurrence_positions_y2027m02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.occurrence_positions_pkey ATTACH PARTITION public.occurrence_positions_y2027m02_pkey;


--
-- Name: occurrence_positions_y2027m02_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_recorded_at ATTACH PARTITION public.occurrence_positions_y2027m02_recorded_at_idx;


--
-- Name: occurrence_positions_y2027m03_occurrence_id_occurrence_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_run ATTACH PARTITION public.occurrence_positions_y2027m03_occurrence_id_occurrence_date_idx;


--
-- Name: occurrence_positions_y2027m03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.occurrence_positions_pkey ATTACH PARTITION public.occurrence_positions_y2027m03_pkey;


--
-- Name: occurrence_positions_y2027m03_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_occurrence_positions_on_recorded_at ATTACH PARTITION public.occurrence_positions_y2027m03_recorded_at_idx;


--
-- Name: trip_occurrences_y2026m09_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_identity ATTACH PARTITION public.trip_occurrences_y2026m09_coalesce_coalesce1_date_coalesce2_idx;


--
-- Name: trip_occurrences_y2026m09_company_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_company_date ATTACH PARTITION public.trip_occurrences_y2026m09_company_id_date_idx;


--
-- Name: trip_occurrences_y2026m09_company_id_date_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_unassigned ATTACH PARTITION public.trip_occurrences_y2026m09_company_id_date_idx1;


--
-- Name: trip_occurrences_y2026m09_company_id_starts_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_starts_at ATTACH PARTITION public.trip_occurrences_y2026m09_company_id_starts_at_idx;


--
-- Name: trip_occurrences_y2026m09_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_driver_date ATTACH PARTITION public.trip_occurrences_y2026m09_driver_id_date_idx;


--
-- Name: trip_occurrences_y2026m09_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_id ATTACH PARTITION public.trip_occurrences_y2026m09_id_idx;


--
-- Name: trip_occurrences_y2026m09_operator_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_operator_driver_date ATTACH PARTITION public.trip_occurrences_y2026m09_operator_driver_id_date_idx;


--
-- Name: trip_occurrences_y2026m09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trip_occurrences_pkey ATTACH PARTITION public.trip_occurrences_y2026m09_pkey;


--
-- Name: trip_occurrences_y2026m09_school_route_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_route_date ATTACH PARTITION public.trip_occurrences_y2026m09_school_route_id_date_idx;


--
-- Name: trip_occurrences_y2026m09_trip_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_trip_date ATTACH PARTITION public.trip_occurrences_y2026m09_trip_id_date_idx;


--
-- Name: trip_occurrences_y2026m09_vehicle_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_vehicle_date ATTACH PARTITION public.trip_occurrences_y2026m09_vehicle_id_date_idx;


--
-- Name: trip_occurrences_y2026m10_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_identity ATTACH PARTITION public.trip_occurrences_y2026m10_coalesce_coalesce1_date_coalesce2_idx;


--
-- Name: trip_occurrences_y2026m10_company_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_company_date ATTACH PARTITION public.trip_occurrences_y2026m10_company_id_date_idx;


--
-- Name: trip_occurrences_y2026m10_company_id_date_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_unassigned ATTACH PARTITION public.trip_occurrences_y2026m10_company_id_date_idx1;


--
-- Name: trip_occurrences_y2026m10_company_id_starts_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_starts_at ATTACH PARTITION public.trip_occurrences_y2026m10_company_id_starts_at_idx;


--
-- Name: trip_occurrences_y2026m10_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_driver_date ATTACH PARTITION public.trip_occurrences_y2026m10_driver_id_date_idx;


--
-- Name: trip_occurrences_y2026m10_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_id ATTACH PARTITION public.trip_occurrences_y2026m10_id_idx;


--
-- Name: trip_occurrences_y2026m10_operator_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_operator_driver_date ATTACH PARTITION public.trip_occurrences_y2026m10_operator_driver_id_date_idx;


--
-- Name: trip_occurrences_y2026m10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trip_occurrences_pkey ATTACH PARTITION public.trip_occurrences_y2026m10_pkey;


--
-- Name: trip_occurrences_y2026m10_school_route_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_route_date ATTACH PARTITION public.trip_occurrences_y2026m10_school_route_id_date_idx;


--
-- Name: trip_occurrences_y2026m10_trip_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_trip_date ATTACH PARTITION public.trip_occurrences_y2026m10_trip_id_date_idx;


--
-- Name: trip_occurrences_y2026m10_vehicle_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_vehicle_date ATTACH PARTITION public.trip_occurrences_y2026m10_vehicle_id_date_idx;


--
-- Name: trip_occurrences_y2026m11_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_identity ATTACH PARTITION public.trip_occurrences_y2026m11_coalesce_coalesce1_date_coalesce2_idx;


--
-- Name: trip_occurrences_y2026m11_company_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_company_date ATTACH PARTITION public.trip_occurrences_y2026m11_company_id_date_idx;


--
-- Name: trip_occurrences_y2026m11_company_id_date_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_unassigned ATTACH PARTITION public.trip_occurrences_y2026m11_company_id_date_idx1;


--
-- Name: trip_occurrences_y2026m11_company_id_starts_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_starts_at ATTACH PARTITION public.trip_occurrences_y2026m11_company_id_starts_at_idx;


--
-- Name: trip_occurrences_y2026m11_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_driver_date ATTACH PARTITION public.trip_occurrences_y2026m11_driver_id_date_idx;


--
-- Name: trip_occurrences_y2026m11_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_id ATTACH PARTITION public.trip_occurrences_y2026m11_id_idx;


--
-- Name: trip_occurrences_y2026m11_operator_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_operator_driver_date ATTACH PARTITION public.trip_occurrences_y2026m11_operator_driver_id_date_idx;


--
-- Name: trip_occurrences_y2026m11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trip_occurrences_pkey ATTACH PARTITION public.trip_occurrences_y2026m11_pkey;


--
-- Name: trip_occurrences_y2026m11_school_route_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_route_date ATTACH PARTITION public.trip_occurrences_y2026m11_school_route_id_date_idx;


--
-- Name: trip_occurrences_y2026m11_trip_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_trip_date ATTACH PARTITION public.trip_occurrences_y2026m11_trip_id_date_idx;


--
-- Name: trip_occurrences_y2026m11_vehicle_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_vehicle_date ATTACH PARTITION public.trip_occurrences_y2026m11_vehicle_id_date_idx;


--
-- Name: trip_occurrences_y2026m12_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_identity ATTACH PARTITION public.trip_occurrences_y2026m12_coalesce_coalesce1_date_coalesce2_idx;


--
-- Name: trip_occurrences_y2026m12_company_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_company_date ATTACH PARTITION public.trip_occurrences_y2026m12_company_id_date_idx;


--
-- Name: trip_occurrences_y2026m12_company_id_date_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_unassigned ATTACH PARTITION public.trip_occurrences_y2026m12_company_id_date_idx1;


--
-- Name: trip_occurrences_y2026m12_company_id_starts_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_starts_at ATTACH PARTITION public.trip_occurrences_y2026m12_company_id_starts_at_idx;


--
-- Name: trip_occurrences_y2026m12_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_driver_date ATTACH PARTITION public.trip_occurrences_y2026m12_driver_id_date_idx;


--
-- Name: trip_occurrences_y2026m12_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_id ATTACH PARTITION public.trip_occurrences_y2026m12_id_idx;


--
-- Name: trip_occurrences_y2026m12_operator_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_operator_driver_date ATTACH PARTITION public.trip_occurrences_y2026m12_operator_driver_id_date_idx;


--
-- Name: trip_occurrences_y2026m12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trip_occurrences_pkey ATTACH PARTITION public.trip_occurrences_y2026m12_pkey;


--
-- Name: trip_occurrences_y2026m12_school_route_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_route_date ATTACH PARTITION public.trip_occurrences_y2026m12_school_route_id_date_idx;


--
-- Name: trip_occurrences_y2026m12_trip_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_trip_date ATTACH PARTITION public.trip_occurrences_y2026m12_trip_id_date_idx;


--
-- Name: trip_occurrences_y2026m12_vehicle_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_vehicle_date ATTACH PARTITION public.trip_occurrences_y2026m12_vehicle_id_date_idx;


--
-- Name: trip_occurrences_y2027m01_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_identity ATTACH PARTITION public.trip_occurrences_y2027m01_coalesce_coalesce1_date_coalesce2_idx;


--
-- Name: trip_occurrences_y2027m01_company_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_company_date ATTACH PARTITION public.trip_occurrences_y2027m01_company_id_date_idx;


--
-- Name: trip_occurrences_y2027m01_company_id_date_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_unassigned ATTACH PARTITION public.trip_occurrences_y2027m01_company_id_date_idx1;


--
-- Name: trip_occurrences_y2027m01_company_id_starts_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_starts_at ATTACH PARTITION public.trip_occurrences_y2027m01_company_id_starts_at_idx;


--
-- Name: trip_occurrences_y2027m01_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_driver_date ATTACH PARTITION public.trip_occurrences_y2027m01_driver_id_date_idx;


--
-- Name: trip_occurrences_y2027m01_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_id ATTACH PARTITION public.trip_occurrences_y2027m01_id_idx;


--
-- Name: trip_occurrences_y2027m01_operator_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_operator_driver_date ATTACH PARTITION public.trip_occurrences_y2027m01_operator_driver_id_date_idx;


--
-- Name: trip_occurrences_y2027m01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trip_occurrences_pkey ATTACH PARTITION public.trip_occurrences_y2027m01_pkey;


--
-- Name: trip_occurrences_y2027m01_school_route_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_route_date ATTACH PARTITION public.trip_occurrences_y2027m01_school_route_id_date_idx;


--
-- Name: trip_occurrences_y2027m01_trip_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_trip_date ATTACH PARTITION public.trip_occurrences_y2027m01_trip_id_date_idx;


--
-- Name: trip_occurrences_y2027m01_vehicle_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_vehicle_date ATTACH PARTITION public.trip_occurrences_y2027m01_vehicle_id_date_idx;


--
-- Name: trip_occurrences_y2027m02_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_identity ATTACH PARTITION public.trip_occurrences_y2027m02_coalesce_coalesce1_date_coalesce2_idx;


--
-- Name: trip_occurrences_y2027m02_company_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_company_date ATTACH PARTITION public.trip_occurrences_y2027m02_company_id_date_idx;


--
-- Name: trip_occurrences_y2027m02_company_id_date_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_unassigned ATTACH PARTITION public.trip_occurrences_y2027m02_company_id_date_idx1;


--
-- Name: trip_occurrences_y2027m02_company_id_starts_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_starts_at ATTACH PARTITION public.trip_occurrences_y2027m02_company_id_starts_at_idx;


--
-- Name: trip_occurrences_y2027m02_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_driver_date ATTACH PARTITION public.trip_occurrences_y2027m02_driver_id_date_idx;


--
-- Name: trip_occurrences_y2027m02_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_id ATTACH PARTITION public.trip_occurrences_y2027m02_id_idx;


--
-- Name: trip_occurrences_y2027m02_operator_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_operator_driver_date ATTACH PARTITION public.trip_occurrences_y2027m02_operator_driver_id_date_idx;


--
-- Name: trip_occurrences_y2027m02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trip_occurrences_pkey ATTACH PARTITION public.trip_occurrences_y2027m02_pkey;


--
-- Name: trip_occurrences_y2027m02_school_route_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_route_date ATTACH PARTITION public.trip_occurrences_y2027m02_school_route_id_date_idx;


--
-- Name: trip_occurrences_y2027m02_trip_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_trip_date ATTACH PARTITION public.trip_occurrences_y2027m02_trip_id_date_idx;


--
-- Name: trip_occurrences_y2027m02_vehicle_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_vehicle_date ATTACH PARTITION public.trip_occurrences_y2027m02_vehicle_id_date_idx;


--
-- Name: trip_occurrences_y2027m03_coalesce_coalesce1_date_coalesce2_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_identity ATTACH PARTITION public.trip_occurrences_y2027m03_coalesce_coalesce1_date_coalesce2_idx;


--
-- Name: trip_occurrences_y2027m03_company_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_company_date ATTACH PARTITION public.trip_occurrences_y2027m03_company_id_date_idx;


--
-- Name: trip_occurrences_y2027m03_company_id_date_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_unassigned ATTACH PARTITION public.trip_occurrences_y2027m03_company_id_date_idx1;


--
-- Name: trip_occurrences_y2027m03_company_id_starts_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_starts_at ATTACH PARTITION public.trip_occurrences_y2027m03_company_id_starts_at_idx;


--
-- Name: trip_occurrences_y2027m03_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_driver_date ATTACH PARTITION public.trip_occurrences_y2027m03_driver_id_date_idx;


--
-- Name: trip_occurrences_y2027m03_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_id ATTACH PARTITION public.trip_occurrences_y2027m03_id_idx;


--
-- Name: trip_occurrences_y2027m03_operator_driver_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_operator_driver_date ATTACH PARTITION public.trip_occurrences_y2027m03_operator_driver_id_date_idx;


--
-- Name: trip_occurrences_y2027m03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trip_occurrences_pkey ATTACH PARTITION public.trip_occurrences_y2027m03_pkey;


--
-- Name: trip_occurrences_y2027m03_school_route_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_route_date ATTACH PARTITION public.trip_occurrences_y2027m03_school_route_id_date_idx;


--
-- Name: trip_occurrences_y2027m03_trip_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_trip_date ATTACH PARTITION public.trip_occurrences_y2027m03_trip_id_date_idx;


--
-- Name: trip_occurrences_y2027m03_vehicle_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_trip_occurrences_on_vehicle_date ATTACH PARTITION public.trip_occurrences_y2027m03_vehicle_id_date_idx;


--
-- Name: school_holidays fk_rails_01b26b908c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_holidays
    ADD CONSTRAINT fk_rails_01b26b908c FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: document_reads fk_rails_02d9fe65e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_reads
    ADD CONSTRAINT fk_rails_02d9fe65e2 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: maintenance_visits fk_rails_030d6ae94e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_visits
    ADD CONSTRAINT fk_rails_030d6ae94e FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: trip_vehicle_slots fk_rails_03257fa7c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_slots
    ADD CONSTRAINT fk_rails_03257fa7c3 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicle_finance_entries fk_rails_035d7d1e35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_finance_entries
    ADD CONSTRAINT fk_rails_035d7d1e35 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: fare_tiers fk_rails_045cbb2886; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tiers
    ADD CONSTRAINT fk_rails_045cbb2886 FOREIGN KEY (fare_table_id) REFERENCES public.fare_tables(id) ON DELETE CASCADE;


--
-- Name: school_holidays fk_rails_06a8bc54e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_holidays
    ADD CONSTRAINT fk_rails_06a8bc54e5 FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: driver_pay_month_lines fk_rails_07029d4bd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_month_lines
    ADD CONSTRAINT fk_rails_07029d4bd7 FOREIGN KEY (driver_pay_month_id) REFERENCES public.driver_pay_months(id);


--
-- Name: pay_scheme_volume_tiers fk_rails_0706a8a3e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_volume_tiers
    ADD CONSTRAINT fk_rails_0706a8a3e8 FOREIGN KEY (pay_scheme_id) REFERENCES public.pay_schemes(id);


--
-- Name: booking_trips fk_rails_071d4c78fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trips
    ADD CONSTRAINT fk_rails_071d4c78fd FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: school_bills fk_rails_080cfd4a0f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT fk_rails_080cfd4a0f FOREIGN KEY (bus_request_id) REFERENCES public.bus_requests(id) ON DELETE SET NULL;


--
-- Name: trip_time_changes fk_rails_08f1eec076; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_time_changes
    ADD CONSTRAINT fk_rails_08f1eec076 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: family_riders fk_rails_092ea116b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_riders
    ADD CONSTRAINT fk_rails_092ea116b3 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: trip_run_times fk_rails_09d9aba0f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_times
    ADD CONSTRAINT fk_rails_09d9aba0f0 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: student_attendances fk_rails_0b23321c06; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT fk_rails_0b23321c06 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: fare_surcharges fk_rails_0b6b26711c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_surcharges
    ADD CONSTRAINT fk_rails_0b6b26711c FOREIGN KEY (fare_table_id) REFERENCES public.fare_tables(id) ON DELETE CASCADE;


--
-- Name: occurrence_correction_stops fk_rails_0c961289ef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_stops
    ADD CONSTRAINT fk_rails_0c961289ef FOREIGN KEY (occurrence_correction_id) REFERENCES public.occurrence_corrections(id);


--
-- Name: booking_trip_vehicles fk_rails_0e030c70e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_vehicles
    ADD CONSTRAINT fk_rails_0e030c70e0 FOREIGN KEY (booking_trip_id) REFERENCES public.booking_trips(id);


--
-- Name: fare_tables fk_rails_0e4a0f3b9d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tables
    ADD CONSTRAINT fk_rails_0e4a0f3b9d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: company_country_requests fk_rails_0eb7327bb9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_country_requests
    ADD CONSTRAINT fk_rails_0eb7327bb9 FOREIGN KEY (decided_by_id) REFERENCES public.users(id);


--
-- Name: maintenance_visits fk_rails_0eb85d280c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_visits
    ADD CONSTRAINT fk_rails_0eb85d280c FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_route_riders fk_rails_0f00e732a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_riders
    ADD CONSTRAINT fk_rails_0f00e732a1 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: feasibility_studies fk_rails_0f3db8379b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_studies
    ADD CONSTRAINT fk_rails_0f3db8379b FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: ops_alerts fk_rails_0f8ee19dca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ops_alerts
    ADD CONSTRAINT fk_rails_0f8ee19dca FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: cca_ride_settings fk_rails_0fe174eb27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_ride_settings
    ADD CONSTRAINT fk_rails_0fe174eb27 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_stops fk_rails_106566a5f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_stops
    ADD CONSTRAINT fk_rails_106566a5f1 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: company_sequences fk_rails_10769b2801; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_sequences
    ADD CONSTRAINT fk_rails_10769b2801 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: maintenance_visits fk_rails_1178e489d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_visits
    ADD CONSTRAINT fk_rails_1178e489d2 FOREIGN KEY (completed_by_id) REFERENCES public.users(id);


--
-- Name: school_holidays fk_rails_1180d6fb4f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_holidays
    ADD CONSTRAINT fk_rails_1180d6fb4f FOREIGN KEY (public_holiday_id) REFERENCES public.public_holidays(id) ON DELETE SET NULL;


--
-- Name: rider_datasets fk_rails_11cb863f8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_datasets
    ADD CONSTRAINT fk_rails_11cb863f8f FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trips fk_rails_122c827faf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_122c827faf FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: client_end_customers fk_rails_1353d28e73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_end_customers
    ADD CONSTRAINT fk_rails_1353d28e73 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: trips fk_rails_13d0b8ef01; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_13d0b8ef01 FOREIGN KEY (pair_id) REFERENCES public.trips(id);


--
-- Name: trip_run_groups fk_rails_13d5d0ee58; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_groups
    ADD CONSTRAINT fk_rails_13d5d0ee58 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: rider_point_links fk_rails_144f7e6539; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_point_links
    ADD CONSTRAINT fk_rails_144f7e6539 FOREIGN KEY (stop_point_id) REFERENCES public.stop_points(id) ON DELETE CASCADE;


--
-- Name: client_invoices fk_rails_145b66b826; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT fk_rails_145b66b826 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: operator_cost_overrides fk_rails_14630333b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_cost_overrides
    ADD CONSTRAINT fk_rails_14630333b6 FOREIGN KEY (set_by_id) REFERENCES public.users(id);


--
-- Name: trip_run_slots fk_rails_15e74e00a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_slots
    ADD CONSTRAINT fk_rails_15e74e00a2 FOREIGN KEY (trip_run_group_id) REFERENCES public.trip_run_groups(id);


--
-- Name: school_plans fk_rails_15ef7f4bd2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plans
    ADD CONSTRAINT fk_rails_15ef7f4bd2 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: school_route_vehicle_changes fk_rails_163f861842; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_vehicle_changes
    ADD CONSTRAINT fk_rails_163f861842 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: client_pickup_points fk_rails_168d0a053a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_pickup_points
    ADD CONSTRAINT fk_rails_168d0a053a FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: rate_cards fk_rails_169aa53d60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_cards
    ADD CONSTRAINT fk_rails_169aa53d60 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: occurrence_corrections fk_rails_16c08b2459; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_corrections
    ADD CONSTRAINT fk_rails_16c08b2459 FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: operator_pay_items fk_rails_16d2bf16ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_items
    ADD CONSTRAINT fk_rails_16d2bf16ff FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: replacements fk_rails_1732b8abb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_1732b8abb6 FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: user_schools fk_rails_176db57c4b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_schools
    ADD CONSTRAINT fk_rails_176db57c4b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: cca_credits fk_rails_17a08a4a60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_credits
    ADD CONSTRAINT fk_rails_17a08a4a60 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_price_cells fk_rails_1acd52e654; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_price_cells
    ADD CONSTRAINT fk_rails_1acd52e654 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: drivers fk_rails_1ae84e42c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT fk_rails_1ae84e42c0 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: maintenance_invoices fk_rails_1babfd3bc0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_invoices
    ADD CONSTRAINT fk_rails_1babfd3bc0 FOREIGN KEY (maintenance_visit_id) REFERENCES public.maintenance_visits(id);


--
-- Name: occurrence_correction_stops fk_rails_1c6e8af693; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_stops
    ADD CONSTRAINT fk_rails_1c6e8af693 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: replacement_notifications fk_rails_1d4ad3b4da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_notifications
    ADD CONSTRAINT fk_rails_1d4ad3b4da FOREIGN KEY (replacement_id) REFERENCES public.replacements(id);


--
-- Name: replacements fk_rails_1d4ec37f27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_1d4ec37f27 FOREIGN KEY (operator_driver_id) REFERENCES public.operator_drivers(id);


--
-- Name: bus_requests fk_rails_1ddef17d9d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_1ddef17d9d FOREIGN KEY (acked_by_id) REFERENCES public.users(id);


--
-- Name: setup_locks fk_rails_1e0921ace2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setup_locks
    ADD CONSTRAINT fk_rails_1e0921ace2 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: maintenance_visits fk_rails_1e55c0c00e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_visits
    ADD CONSTRAINT fk_rails_1e55c0c00e FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: school_bills fk_rails_1ef4249f68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT fk_rails_1ef4249f68 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: school_registrations fk_rails_202668a2c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_registrations
    ADD CONSTRAINT fk_rails_202668a2c2 FOREIGN KEY (saved_by_id) REFERENCES public.users(id);


--
-- Name: setup_locks fk_rails_2068c8b709; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setup_locks
    ADD CONSTRAINT fk_rails_2068c8b709 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_sites fk_rails_206a27dfcd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_sites
    ADD CONSTRAINT fk_rails_206a27dfcd FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: replacements fk_rails_20ad5cb2d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_20ad5cb2d5 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_invoice_sends fk_rails_20f1ed100b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_sends
    ADD CONSTRAINT fk_rails_20f1ed100b FOREIGN KEY (sent_by_id) REFERENCES public.users(id);


--
-- Name: document_reads fk_rails_210a1ba5bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_reads
    ADD CONSTRAINT fk_rails_210a1ba5bb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: rate_card_rates fk_rails_211ce9ac3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_rates
    ADD CONSTRAINT fk_rails_211ce9ac3c FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: rider_point_links fk_rails_2164356d09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_point_links
    ADD CONSTRAINT fk_rails_2164356d09 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: academic_years fk_rails_22c22c5702; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT fk_rails_22c22c5702 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_standby_photos fk_rails_233b0eaa96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_standby_photos
    ADD CONSTRAINT fk_rails_233b0eaa96 FOREIGN KEY (trip_standby_id) REFERENCES public.trip_standbys(id);


--
-- Name: school_routes fk_rails_237bacfac4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_routes
    ADD CONSTRAINT fk_rails_237bacfac4 FOREIGN KEY (attendant_id) REFERENCES public.attendants(id);


--
-- Name: vehicle_insurance_policies fk_rails_23b5f436d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_insurance_policies
    ADD CONSTRAINT fk_rails_23b5f436d3 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: vehicle_cost_spike_acks fk_rails_250676ae3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_cost_spike_acks
    ADD CONSTRAINT fk_rails_250676ae3d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: cca_off_days fk_rails_2578850e0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_off_days
    ADD CONSTRAINT fk_rails_2578850e0b FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: occurrence_report_photos fk_rails_25b7d44265; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_report_photos
    ADD CONSTRAINT fk_rails_25b7d44265 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_route_replacements fk_rails_26779f70c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_replacements
    ADD CONSTRAINT fk_rails_26779f70c2 FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id);


--
-- Name: maintenance_lines fk_rails_26883d1f42; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_lines
    ADD CONSTRAINT fk_rails_26883d1f42 FOREIGN KEY (maintenance_visit_id) REFERENCES public.maintenance_visits(id);


--
-- Name: replacements fk_rails_2773161756; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_2773161756 FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id);


--
-- Name: vehicle_financials fk_rails_27c76f39c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_financials
    ADD CONSTRAINT fk_rails_27c76f39c4 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: notice_templates fk_rails_27db3d4c85; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_templates
    ADD CONSTRAINT fk_rails_27db3d4c85 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: bookings fk_rails_27f28f8694; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT fk_rails_27f28f8694 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: ops_alerts fk_rails_289112610b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ops_alerts
    ADD CONSTRAINT fk_rails_289112610b FOREIGN KEY (acknowledged_by_id) REFERENCES public.users(id);


--
-- Name: external_vehicle_submissions fk_rails_29f2db1b3a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_submissions
    ADD CONSTRAINT fk_rails_29f2db1b3a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicle_live_positions fk_rails_29f5d7c051; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_live_positions
    ADD CONSTRAINT fk_rails_29f5d7c051 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: client_invoice_payments fk_rails_29fd7196e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_payments
    ADD CONSTRAINT fk_rails_29fd7196e6 FOREIGN KEY (client_invoice_id) REFERENCES public.client_invoices(id);


--
-- Name: user_schools fk_rails_2a059e4b44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_schools
    ADD CONSTRAINT fk_rails_2a059e4b44 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: vehicle_insurance_documents fk_rails_2a52534714; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_insurance_documents
    ADD CONSTRAINT fk_rails_2a52534714 FOREIGN KEY (vehicle_insurance_policy_id) REFERENCES public.vehicle_insurance_policies(id);


--
-- Name: notices fk_rails_2c1a9f3de6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT fk_rails_2c1a9f3de6 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: bookings fk_rails_2c503ea743; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT fk_rails_2c503ea743 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: operator_pay_batch_operators fk_rails_2c6448497f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batch_operators
    ADD CONSTRAINT fk_rails_2c6448497f FOREIGN KEY (operator_pay_batch_id) REFERENCES public.operator_pay_batches(id);


--
-- Name: bus_request_places fk_rails_2c98bd2192; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_places
    ADD CONSTRAINT fk_rails_2c98bd2192 FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id) ON DELETE SET NULL;


--
-- Name: driver_point_deductions fk_rails_2d9881cfe8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_deductions
    ADD CONSTRAINT fk_rails_2d9881cfe8 FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: route_charges fk_rails_2f27515a7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_charges
    ADD CONSTRAINT fk_rails_2f27515a7e FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: disabled_vehicle_types fk_rails_30090ae9aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_vehicle_types
    ADD CONSTRAINT fk_rails_30090ae9aa FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: academic_terms fk_rails_3030cefefe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_terms
    ADD CONSTRAINT fk_rails_3030cefefe FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: operator_pay_batch_operators fk_rails_306e85c95a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batch_operators
    ADD CONSTRAINT fk_rails_306e85c95a FOREIGN KEY (operator_id) REFERENCES public.operators(id);


--
-- Name: client_invoice_lines fk_rails_306fa46511; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_lines
    ADD CONSTRAINT fk_rails_306fa46511 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: client_invoices fk_rails_30cc8daca1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT fk_rails_30cc8daca1 FOREIGN KEY (issued_by_id) REFERENCES public.users(id);


--
-- Name: pay_rate_plans fk_rails_3120067d0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_plans
    ADD CONSTRAINT fk_rails_3120067d0c FOREIGN KEY (locked_by_id) REFERENCES public.users(id);


--
-- Name: trip_assignment_slots fk_rails_3142be0430; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignment_slots
    ADD CONSTRAINT fk_rails_3142be0430 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicles fk_rails_314b522c0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_rails_314b522c0a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_bookable_vehicle_types fk_rails_315586af8c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_bookable_vehicle_types
    ADD CONSTRAINT fk_rails_315586af8c FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: finance_settings fk_rails_32019f445e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_settings
    ADD CONSTRAINT fk_rails_32019f445e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: driver_point_allocations fk_rails_3336a5f9a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_allocations
    ADD CONSTRAINT fk_rails_3336a5f9a3 FOREIGN KEY (driver_point_deduction_id) REFERENCES public.driver_point_deductions(id);


--
-- Name: pay_bonus_tiers fk_rails_336d373138; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_tiers
    ADD CONSTRAINT fk_rails_336d373138 FOREIGN KEY (pay_bonus_id) REFERENCES public.pay_bonuses(id);


--
-- Name: booking_events fk_rails_33f1a57bbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_events
    ADD CONSTRAINT fk_rails_33f1a57bbd FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: operator_drivers fk_rails_3495875770; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers
    ADD CONSTRAINT fk_rails_3495875770 FOREIGN KEY (display_set_by_id) REFERENCES public.users(id);


--
-- Name: trip_stop_students fk_rails_34efd4f967; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_students
    ADD CONSTRAINT fk_rails_34efd4f967 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_standbys fk_rails_34f438cd3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_standbys
    ADD CONSTRAINT fk_rails_34f438cd3b FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: feasibility_studies fk_rails_3595ec5633; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_studies
    ADD CONSTRAINT fk_rails_3595ec5633 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: pay_rewards fk_rails_35c40ffc56; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rewards
    ADD CONSTRAINT fk_rails_35c40ffc56 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: calendar_days fk_rails_363537453d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_days
    ADD CONSTRAINT fk_rails_363537453d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: cca_bookings fk_rails_3771471671; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_bookings
    ADD CONSTRAINT fk_rails_3771471671 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: schools fk_rails_379253fa8b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT fk_rails_379253fa8b FOREIGN KEY (calendar_id) REFERENCES public.calendars(id);


--
-- Name: company_country_requests fk_rails_382fbe2df2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_country_requests
    ADD CONSTRAINT fk_rails_382fbe2df2 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: booking_trip_changes fk_rails_384b65f57b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_changes
    ADD CONSTRAINT fk_rails_384b65f57b FOREIGN KEY (booking_trip_id) REFERENCES public.booking_trips(id);


--
-- Name: client_end_customers fk_rails_38fb529cd4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_end_customers
    ADD CONSTRAINT fk_rails_38fb529cd4 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: cca_credits fk_rails_39552483c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_credits
    ADD CONSTRAINT fk_rails_39552483c1 FOREIGN KEY (cca_booking_id) REFERENCES public.cca_bookings(id) ON DELETE SET NULL;


--
-- Name: rate_card_ranges fk_rails_39ec7b3cd8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_ranges
    ADD CONSTRAINT fk_rails_39ec7b3cd8 FOREIGN KEY (rate_card_period_id) REFERENCES public.rate_card_periods(id);


--
-- Name: tracking_devices fk_rails_39eff8f687; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_devices
    ADD CONSTRAINT fk_rails_39eff8f687 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicle_finance_entries fk_rails_3a01e60fe6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_finance_entries
    ADD CONSTRAINT fk_rails_3a01e60fe6 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: occurrence_driver_reports fk_rails_3a963001f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_driver_reports
    ADD CONSTRAINT fk_rails_3a963001f8 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fare_adjustments fk_rails_3b77c359af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_adjustments
    ADD CONSTRAINT fk_rails_3b77c359af FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: client_users fk_rails_3b88600172; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_users
    ADD CONSTRAINT fk_rails_3b88600172 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: client_sites fk_rails_3b956d0844; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_sites
    ADD CONSTRAINT fk_rails_3b956d0844 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: school_policy_versions fk_rails_3badfff195; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_policy_versions
    ADD CONSTRAINT fk_rails_3badfff195 FOREIGN KEY (published_by_id) REFERENCES public.users(id);


--
-- Name: school_plan_changes fk_rails_3bf4d20c9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plan_changes
    ADD CONSTRAINT fk_rails_3bf4d20c9e FOREIGN KEY (school_plan_id) REFERENCES public.school_plans(id) ON DELETE CASCADE;


--
-- Name: trip_stops fk_rails_3c5be21545; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT fk_rails_3c5be21545 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: stops fk_rails_3caa2b5528; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stops
    ADD CONSTRAINT fk_rails_3caa2b5528 FOREIGN KEY (owner_school_id) REFERENCES public.schools(id);


--
-- Name: driver_point_deductions fk_rails_3d387a27be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_deductions
    ADD CONSTRAINT fk_rails_3d387a27be FOREIGN KEY (deducted_by_id) REFERENCES public.users(id);


--
-- Name: allowlisted_jwts fk_rails_3d594c2c7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allowlisted_jwts
    ADD CONSTRAINT fk_rails_3d594c2c7d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicle_log_cards fk_rails_3d7d7f8b86; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_log_cards
    ADD CONSTRAINT fk_rails_3d7d7f8b86 FOREIGN KEY (uploaded_by_id) REFERENCES public.users(id);


--
-- Name: driver_pay_schemes fk_rails_3d8de34246; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_schemes
    ADD CONSTRAINT fk_rails_3d8de34246 FOREIGN KEY (pay_scheme_id) REFERENCES public.pay_schemes(id);


--
-- Name: operator_pay_batches fk_rails_3da0f1a924; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batches
    ADD CONSTRAINT fk_rails_3da0f1a924 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: families fk_rails_3e132c8baa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.families
    ADD CONSTRAINT fk_rails_3e132c8baa FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: school_special_days fk_rails_3e1e1eb494; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_special_days
    ADD CONSTRAINT fk_rails_3e1e1eb494 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_riders fk_rails_3f1b5106c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_riders
    ADD CONSTRAINT fk_rails_3f1b5106c7 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fare_adjustments fk_rails_3f2faed1e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_adjustments
    ADD CONSTRAINT fk_rails_3f2faed1e0 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: stops fk_rails_3f773c03f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stops
    ADD CONSTRAINT fk_rails_3f773c03f5 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: maintenance_visits fk_rails_3f8af294e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_visits
    ADD CONSTRAINT fk_rails_3f8af294e5 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: replacement_notifications fk_rails_40ebd31033; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_notifications
    ADD CONSTRAINT fk_rails_40ebd31033 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: bank_branches fk_rails_419b0e49fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_branches
    ADD CONSTRAINT fk_rails_419b0e49fb FOREIGN KEY (bank_id) REFERENCES public.banks(id);


--
-- Name: school_plans fk_rails_41ca1bd05a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plans
    ADD CONSTRAINT fk_rails_41ca1bd05a FOREIGN KEY (adopted_by_id) REFERENCES public.users(id);


--
-- Name: student_attendances fk_rails_41d39c3bea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT fk_rails_41d39c3bea FOREIGN KEY (recorded_by_id) REFERENCES public.users(id);


--
-- Name: finance_settings fk_rails_41d877d9bf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_settings
    ADD CONSTRAINT fk_rails_41d877d9bf FOREIGN KEY (bank_id) REFERENCES public.banks(id);


--
-- Name: workshops fk_rails_42ed2095b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workshops
    ADD CONSTRAINT fk_rails_42ed2095b4 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: operator_pay_items fk_rails_432069dad3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_items
    ADD CONSTRAINT fk_rails_432069dad3 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: fuel_alerts fk_rails_442ba1cc4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_alerts
    ADD CONSTRAINT fk_rails_442ba1cc4d FOREIGN KEY (checked_by_id) REFERENCES public.users(id);


--
-- Name: school_route_labels fk_rails_44991d1790; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_labels
    ADD CONSTRAINT fk_rails_44991d1790 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_invoice_sends fk_rails_44cb95a774; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_sends
    ADD CONSTRAINT fk_rails_44cb95a774 FOREIGN KEY (client_invoice_id) REFERENCES public.client_invoices(id);


--
-- Name: users fk_rails_45307c95a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_45307c95a3 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: bus_request_answer_moves fk_rails_456dee1276; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_answer_moves
    ADD CONSTRAINT fk_rails_456dee1276 FOREIGN KEY (bus_request_id) REFERENCES public.bus_requests(id) ON DELETE CASCADE;


--
-- Name: route_list_version_stops fk_rails_45b437b78c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_version_stops
    ADD CONSTRAINT fk_rails_45b437b78c FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trips fk_rails_45cc0c7a87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_45cc0c7a87 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: booking_events fk_rails_463f96d8db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_events
    ADD CONSTRAINT fk_rails_463f96d8db FOREIGN KEY (booking_trip_id) REFERENCES public.booking_trips(id);


--
-- Name: stop_photo_requests fk_rails_46f53ae8fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_requests
    ADD CONSTRAINT fk_rails_46f53ae8fc FOREIGN KEY (school_rider_id) REFERENCES public.school_riders(id) ON DELETE SET NULL;


--
-- Name: trip_time_changes fk_rails_474b871dfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_time_changes
    ADD CONSTRAINT fk_rails_474b871dfa FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: driver_app_sessions fk_rails_48207a8c17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_app_sessions
    ADD CONSTRAINT fk_rails_48207a8c17 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_assignments fk_rails_487a71f2ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT fk_rails_487a71f2ab FOREIGN KEY (operator_id) REFERENCES public.operators(id);


--
-- Name: vehicle_financials fk_rails_48a3146f75; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_financials
    ADD CONSTRAINT fk_rails_48a3146f75 FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: bus_requests fk_rails_48caf13dad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_48caf13dad FOREIGN KEY (ended_by_id) REFERENCES public.users(id);


--
-- Name: school_bills fk_rails_4962e981b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT fk_rails_4962e981b5 FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE SET NULL;


--
-- Name: stop_photo_requests fk_rails_499bc1f1e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_requests
    ADD CONSTRAINT fk_rails_499bc1f1e2 FOREIGN KEY (stop_point_id) REFERENCES public.stop_points(id) ON DELETE CASCADE;


--
-- Name: occurrence_trip_summaries fk_rails_49da7d8c5a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_trip_summaries
    ADD CONSTRAINT fk_rails_49da7d8c5a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_stops fk_rails_49eb5c0714; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT fk_rails_49eb5c0714 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: occurrence_stop_events fk_rails_4a0b69ac2e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_stop_events
    ADD CONSTRAINT fk_rails_4a0b69ac2e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: occurrence_corrections fk_rails_4a8407703d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_corrections
    ADD CONSTRAINT fk_rails_4a8407703d FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: maintenance_invoices fk_rails_4ad6b17d98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_invoices
    ADD CONSTRAINT fk_rails_4ad6b17d98 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: routing_runs fk_rails_4c925b4625; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_runs
    ADD CONSTRAINT fk_rails_4c925b4625 FOREIGN KEY (target_plan_id) REFERENCES public.school_plans(id) ON DELETE CASCADE;


--
-- Name: pay_bonus_drivers fk_rails_4d06340649; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_drivers
    ADD CONSTRAINT fk_rails_4d06340649 FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: school_registrations fk_rails_4d3d69ce48; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_registrations
    ADD CONSTRAINT fk_rails_4d3d69ce48 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: school_stops fk_rails_4d9eedee56; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_stops
    ADD CONSTRAINT fk_rails_4d9eedee56 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: client_invoices fk_rails_4dfd75ad8a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT fk_rails_4dfd75ad8a FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: replacements fk_rails_4e1f22325d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_4e1f22325d FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: booking_trip_points fk_rails_4e24e0dd72; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_points
    ADD CONSTRAINT fk_rails_4e24e0dd72 FOREIGN KEY (booking_trip_id) REFERENCES public.booking_trips(id);


--
-- Name: rider_assignments fk_rails_4e588de00c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT fk_rails_4e588de00c FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: stop_points fk_rails_4ea8678acf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_points
    ADD CONSTRAINT fk_rails_4ea8678acf FOREIGN KEY (stop_id) REFERENCES public.stops(id) ON DELETE CASCADE;


--
-- Name: notification_emails fk_rails_4ecceae2e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_emails
    ADD CONSTRAINT fk_rails_4ecceae2e7 FOREIGN KEY (booking_event_id) REFERENCES public.booking_events(id);


--
-- Name: booking_trip_vehicles fk_rails_4fca287106; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_vehicles
    ADD CONSTRAINT fk_rails_4fca287106 FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: fare_adjustments fk_rails_518ebad3d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_adjustments
    ADD CONSTRAINT fk_rails_518ebad3d3 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: bus_requests fk_rails_5198383da3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_5198383da3 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: booking_attachments fk_rails_51c3735ca4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_attachments
    ADD CONSTRAINT fk_rails_51c3735ca4 FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: trip_run_times fk_rails_51d11f242c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_times
    ADD CONSTRAINT fk_rails_51d11f242c FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: driver_point_lots fk_rails_5338c4769c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_lots
    ADD CONSTRAINT fk_rails_5338c4769c FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: fare_tier_sizes fk_rails_5339c48f41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tier_sizes
    ADD CONSTRAINT fk_rails_5339c48f41 FOREIGN KEY (fare_size_column_id) REFERENCES public.fare_size_columns(id) ON DELETE CASCADE;


--
-- Name: driver_pay_months fk_rails_544d3f5bca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_months
    ADD CONSTRAINT fk_rails_544d3f5bca FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: booking_attachments fk_rails_54e3badbf9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_attachments
    ADD CONSTRAINT fk_rails_54e3badbf9 FOREIGN KEY (uploaded_by_id) REFERENCES public.users(id);


--
-- Name: trip_price_cells fk_rails_55263bd202; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_price_cells
    ADD CONSTRAINT fk_rails_55263bd202 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: occurrence_report_photos fk_rails_55680d95df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_report_photos
    ADD CONSTRAINT fk_rails_55680d95df FOREIGN KEY (occurrence_driver_report_id) REFERENCES public.occurrence_driver_reports(id);


--
-- Name: rate_card_amounts fk_rails_55cb4a1d24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_amounts
    ADD CONSTRAINT fk_rails_55cb4a1d24 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: booking_trip_standbys fk_rails_55e97f3236; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_standbys
    ADD CONSTRAINT fk_rails_55e97f3236 FOREIGN KEY (booking_trip_id) REFERENCES public.booking_trips(id);


--
-- Name: client_invoices fk_rails_5656e3e8cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT fk_rails_5656e3e8cb FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: pay_rate_plans fk_rails_57a64691d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_plans
    ADD CONSTRAINT fk_rails_57a64691d8 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_vehicle_requirements fk_rails_57c7ef98d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_requirements
    ADD CONSTRAINT fk_rails_57c7ef98d4 FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: booking_days fk_rails_587e3d5483; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_days
    ADD CONSTRAINT fk_rails_587e3d5483 FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: notices fk_rails_58ddb7aeba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT fk_rails_58ddb7aeba FOREIGN KEY (ended_by_id) REFERENCES public.users(id);


--
-- Name: trip_standby_photos fk_rails_58f10f94a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_standby_photos
    ADD CONSTRAINT fk_rails_58f10f94a3 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: bus_sessions fk_rails_595da3563f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_sessions
    ADD CONSTRAINT fk_rails_595da3563f FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: maintenance_lines fk_rails_5a4724ac90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_lines
    ADD CONSTRAINT fk_rails_5a4724ac90 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: operator_pay_batch_lines fk_rails_5a6580df3a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batch_lines
    ADD CONSTRAINT fk_rails_5a6580df3a FOREIGN KEY (operator_pay_batch_operator_id) REFERENCES public.operator_pay_batch_operators(id);


--
-- Name: school_plans fk_rails_5b090d2597; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plans
    ADD CONSTRAINT fk_rails_5b090d2597 FOREIGN KEY (routing_run_id) REFERENCES public.routing_runs(id) ON DELETE SET NULL;


--
-- Name: client_user_sites fk_rails_5b94d5bb39; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_user_sites
    ADD CONSTRAINT fk_rails_5b94d5bb39 FOREIGN KEY (client_site_id) REFERENCES public.client_sites(id);


--
-- Name: bus_sessions fk_rails_5bb177b8a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_sessions
    ADD CONSTRAINT fk_rails_5bb177b8a9 FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: schools fk_rails_5c21ed42ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT fk_rails_5c21ed42ac FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicle_driver_schedules fk_rails_5d7d8402cd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT fk_rails_5d7d8402cd FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: bus_requests fk_rails_5d996c1a5e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_5d996c1a5e FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id);


--
-- Name: driver_point_lots fk_rails_5e53cb2a93; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_lots
    ADD CONSTRAINT fk_rails_5e53cb2a93 FOREIGN KEY (driver_pay_month_id) REFERENCES public.driver_pay_months(id);


--
-- Name: bus_session_variants fk_rails_5e66e67131; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_session_variants
    ADD CONSTRAINT fk_rails_5e66e67131 FOREIGN KEY (bus_session_id) REFERENCES public.bus_sessions(id) ON DELETE CASCADE;


--
-- Name: school_plans fk_rails_5eb2dc3cfc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plans
    ADD CONSTRAINT fk_rails_5eb2dc3cfc FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: pickup_points fk_rails_5eeabc1609; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pickup_points
    ADD CONSTRAINT fk_rails_5eeabc1609 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_riders fk_rails_5f549d3cd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_riders
    ADD CONSTRAINT fk_rails_5f549d3cd7 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: trip_runs fk_rails_5f8bb73316; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_runs
    ADD CONSTRAINT fk_rails_5f8bb73316 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: school_policy_versions fk_rails_5fb4e23c02; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_policy_versions
    ADD CONSTRAINT fk_rails_5fb4e23c02 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: trip_stop_photos fk_rails_600dadf610; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_photos
    ADD CONSTRAINT fk_rails_600dadf610 FOREIGN KEY (trip_stop_id) REFERENCES public.trip_stops(id);


--
-- Name: discover_placements fk_rails_610c88f5ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discover_placements
    ADD CONSTRAINT fk_rails_610c88f5ba FOREIGN KEY (run_by_company_id) REFERENCES public.companies(id);


--
-- Name: message_terms fk_rails_6138cd0b1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_terms
    ADD CONSTRAINT fk_rails_6138cd0b1e FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: vehicle_teams fk_rails_620cfa77f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_teams
    ADD CONSTRAINT fk_rails_620cfa77f0 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_operator_pays fk_rails_6336137d8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_operator_pays
    ADD CONSTRAINT fk_rails_6336137d8f FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: pay_bonus_drivers fk_rails_6370488d2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_drivers
    ADD CONSTRAINT fk_rails_6370488d2c FOREIGN KEY (signed_up_by_id) REFERENCES public.users(id);


--
-- Name: trip_stop_photos fk_rails_6457b1f23d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_photos
    ADD CONSTRAINT fk_rails_6457b1f23d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: notice_runs fk_rails_64f4e90b1d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_runs
    ADD CONSTRAINT fk_rails_64f4e90b1d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_vehicle_slots fk_rails_6518ccacab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_slots
    ADD CONSTRAINT fk_rails_6518ccacab FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: finance_approvers fk_rails_656c503d74; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_approvers
    ADD CONSTRAINT fk_rails_656c503d74 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trips fk_rails_657f0f6ab4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_657f0f6ab4 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fuel_entries fk_rails_65f83d796e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_entries
    ADD CONSTRAINT fk_rails_65f83d796e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rider_point_links fk_rails_65febeda34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_point_links
    ADD CONSTRAINT fk_rails_65febeda34 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: feasibility_rows fk_rails_6616ee2b7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_rows
    ADD CONSTRAINT fk_rails_6616ee2b7e FOREIGN KEY (feasibility_study_id) REFERENCES public.feasibility_studies(id) ON DELETE CASCADE;


--
-- Name: pay_bonus_excluded_periods fk_rails_66ae344984; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_excluded_periods
    ADD CONSTRAINT fk_rails_66ae344984 FOREIGN KEY (pay_bonus_id) REFERENCES public.pay_bonuses(id);


--
-- Name: bus_requests fk_rails_66df860e66; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_66df860e66 FOREIGN KEY (school_rider_id) REFERENCES public.school_riders(id) ON DELETE SET NULL;


--
-- Name: portal_sign_in_codes fk_rails_6774558f0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_sign_in_codes
    ADD CONSTRAINT fk_rails_6774558f0a FOREIGN KEY (portal_account_id) REFERENCES public.portal_accounts(id);


--
-- Name: vehicles fk_rails_679fe54be7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_rails_679fe54be7 FOREIGN KEY (vehicle_team_id) REFERENCES public.vehicle_teams(id);


--
-- Name: operator_pay_items fk_rails_67abf15496; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_items
    ADD CONSTRAINT fk_rails_67abf15496 FOREIGN KEY (operator_id) REFERENCES public.operators(id);


--
-- Name: replacement_notifications fk_rails_67e910e45e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacement_notifications
    ADD CONSTRAINT fk_rails_67e910e45e FOREIGN KEY (sent_by_id) REFERENCES public.users(id);


--
-- Name: school_operator_pays fk_rails_69947fe099; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_operator_pays
    ADD CONSTRAINT fk_rails_69947fe099 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_bills fk_rails_69fb86e1a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT fk_rails_69fb86e1a9 FOREIGN KEY (school_rider_id) REFERENCES public.school_riders(id) ON DELETE SET NULL;


--
-- Name: operator_pay_batches fk_rails_6a1c0f4d70; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batches
    ADD CONSTRAINT fk_rails_6a1c0f4d70 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: stops fk_rails_6a29505dff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stops
    ADD CONSTRAINT fk_rails_6a29505dff FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: family_riders fk_rails_6aea621432; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_riders
    ADD CONSTRAINT fk_rails_6aea621432 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: notice_routes fk_rails_6c220f93f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_routes
    ADD CONSTRAINT fk_rails_6c220f93f2 FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id);


--
-- Name: booking_trip_points fk_rails_6c2d4acf3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_points
    ADD CONSTRAINT fk_rails_6c2d4acf3b FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: routing_settings fk_rails_6ccbc22684; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_settings
    ADD CONSTRAINT fk_rails_6ccbc22684 FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: vehicle_type_requests fk_rails_6d4aaf983d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_type_requests
    ADD CONSTRAINT fk_rails_6d4aaf983d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_attachments fk_rails_6d6699756b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_attachments
    ADD CONSTRAINT fk_rails_6d6699756b FOREIGN KEY (uploaded_by_id) REFERENCES public.users(id);


--
-- Name: trip_run_slots fk_rails_6d6b4091a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_slots
    ADD CONSTRAINT fk_rails_6d6b4091a8 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: pay_simulator_templates fk_rails_6db026d8ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_simulator_templates
    ADD CONSTRAINT fk_rails_6db026d8ba FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: trips fk_rails_6df0f7663f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_6df0f7663f FOREIGN KEY (booking_trip_id) REFERENCES public.booking_trips(id);


--
-- Name: academic_years fk_rails_6f46cfb03a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT fk_rails_6f46cfb03a FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: cca_ride_settings fk_rails_6feced6f4f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_ride_settings
    ADD CONSTRAINT fk_rails_6feced6f4f FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: booking_cancel_requests fk_rails_7045621129; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_cancel_requests
    ADD CONSTRAINT fk_rails_7045621129 FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: vehicle_financials fk_rails_704e5a7d24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_financials
    ADD CONSTRAINT fk_rails_704e5a7d24 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: vehicle_insurance_documents fk_rails_715b535d8e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_insurance_documents
    ADD CONSTRAINT fk_rails_715b535d8e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: pay_simulator_templates fk_rails_716eb53881; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_simulator_templates
    ADD CONSTRAINT fk_rails_716eb53881 FOREIGN KEY (saved_by_id) REFERENCES public.users(id);


--
-- Name: rider_assignments fk_rails_71881150e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT fk_rails_71881150e5 FOREIGN KEY (stop_point_id) REFERENCES public.stop_points(id) ON DELETE CASCADE;


--
-- Name: school_route_stops fk_rails_719f8a7524; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_stops
    ADD CONSTRAINT fk_rails_719f8a7524 FOREIGN KEY (stop_point_id) REFERENCES public.stop_points(id);


--
-- Name: feasibility_studies fk_rails_71a6bbf8c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_studies
    ADD CONSTRAINT fk_rails_71a6bbf8c9 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: rider_datasets fk_rails_71ebe39e12; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_datasets
    ADD CONSTRAINT fk_rails_71ebe39e12 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: trip_assignment_slots fk_rails_71efc7bfaa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignment_slots
    ADD CONSTRAINT fk_rails_71efc7bfaa FOREIGN KEY (trip_assignment_id) REFERENCES public.trip_assignments(id);


--
-- Name: notice_deliveries fk_rails_72f3faea95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_deliveries
    ADD CONSTRAINT fk_rails_72f3faea95 FOREIGN KEY (notice_id) REFERENCES public.notices(id);


--
-- Name: school_route_stops fk_rails_737e406191; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_stops
    ADD CONSTRAINT fk_rails_737e406191 FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id);


--
-- Name: trip_vehicle_requirements fk_rails_7380020934; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_requirements
    ADD CONSTRAINT fk_rails_7380020934 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: occurrence_notes fk_rails_7387d474bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_notes
    ADD CONSTRAINT fk_rails_7387d474bb FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: notification_emails fk_rails_73c46ea3cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_emails
    ADD CONSTRAINT fk_rails_73c46ea3cc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: vehicle_driver_schedules fk_rails_745a342283; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT fk_rails_745a342283 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_payment_methods fk_rails_74ae3c9c9f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_payment_methods
    ADD CONSTRAINT fk_rails_74ae3c9c9f FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: users fk_rails_7682a3bdfe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_7682a3bdfe FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_routes fk_rails_768b97a056; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_routes
    ADD CONSTRAINT fk_rails_768b97a056 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: cca_off_days fk_rails_77624a6b1f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_off_days
    ADD CONSTRAINT fk_rails_77624a6b1f FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: rider_point_links fk_rails_7762b8c81f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_point_links
    ADD CONSTRAINT fk_rails_7762b8c81f FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: cca_bookings fk_rails_776370984b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_bookings
    ADD CONSTRAINT fk_rails_776370984b FOREIGN KEY (school_rider_id) REFERENCES public.school_riders(id) ON DELETE SET NULL;


--
-- Name: allowlisted_jwts fk_rails_77afa78cd5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allowlisted_jwts
    ADD CONSTRAINT fk_rails_77afa78cd5 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: rate_card_amounts fk_rails_780a986664; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_amounts
    ADD CONSTRAINT fk_rails_780a986664 FOREIGN KEY (rate_card_distance_band_id) REFERENCES public.rate_card_distance_bands(id);


--
-- Name: trip_assignments fk_rails_7a3d568c06; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT fk_rails_7a3d568c06 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fare_adjustments fk_rails_7a42b755e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_adjustments
    ADD CONSTRAINT fk_rails_7a42b755e7 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: school_payment_methods fk_rails_7ab716f530; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_payment_methods
    ADD CONSTRAINT fk_rails_7ab716f530 FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: pay_bonus_payments fk_rails_7b8fed7102; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_payments
    ADD CONSTRAINT fk_rails_7b8fed7102 FOREIGN KEY (pay_bonus_id) REFERENCES public.pay_bonuses(id);


--
-- Name: driver_app_sessions fk_rails_7c8e32aeec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_app_sessions
    ADD CONSTRAINT fk_rails_7c8e32aeec FOREIGN KEY (operator_driver_id) REFERENCES public.operator_drivers(id);


--
-- Name: booking_days fk_rails_7cbe55c381; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_days
    ADD CONSTRAINT fk_rails_7cbe55c381 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rider_assignments fk_rails_7d7912020c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT fk_rails_7d7912020c FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: notices fk_rails_7e3081eff2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT fk_rails_7e3081eff2 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: pay_rates fk_rails_7e44714815; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rates
    ADD CONSTRAINT fk_rails_7e44714815 FOREIGN KEY (pay_rate_period_id) REFERENCES public.pay_rate_periods(id);


--
-- Name: vehicle_type_requests fk_rails_7e6b1ee420; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_type_requests
    ADD CONSTRAINT fk_rails_7e6b1ee420 FOREIGN KEY (decided_by_id) REFERENCES public.users(id);


--
-- Name: pay_scheme_target_tiers fk_rails_7eab46fd97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_target_tiers
    ADD CONSTRAINT fk_rails_7eab46fd97 FOREIGN KEY (pay_scheme_id) REFERENCES public.pay_schemes(id);


--
-- Name: vehicle_live_positions fk_rails_7fbadb7b8d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_live_positions
    ADD CONSTRAINT fk_rails_7fbadb7b8d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: replacements fk_rails_7fd7950604; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_7fd7950604 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: company_country_requests fk_rails_7ffe4ed24b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_country_requests
    ADD CONSTRAINT fk_rails_7ffe4ed24b FOREIGN KEY (requested_by_id) REFERENCES public.users(id);


--
-- Name: booking_trip_changes fk_rails_804f184d1f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_changes
    ADD CONSTRAINT fk_rails_804f184d1f FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_time_changes fk_rails_8074f3425b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_time_changes
    ADD CONSTRAINT fk_rails_8074f3425b FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: trip_standbys fk_rails_811768cb79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_standbys
    ADD CONSTRAINT fk_rails_811768cb79 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: cca_bookings fk_rails_815dc36664; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_bookings
    ADD CONSTRAINT fk_rails_815dc36664 FOREIGN KEY (school_bill_id) REFERENCES public.school_bills(id) ON DELETE SET NULL;


--
-- Name: clients fk_rails_817e50a5ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT fk_rails_817e50a5ab FOREIGN KEY (rate_card_id) REFERENCES public.rate_cards(id);


--
-- Name: bus_request_answer_moves fk_rails_827fc6a3a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_answer_moves
    ADD CONSTRAINT fk_rails_827fc6a3a0 FOREIGN KEY (moved_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: trip_run_groups fk_rails_82b08ef03f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_groups
    ADD CONSTRAINT fk_rails_82b08ef03f FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: stop_photo_requests fk_rails_82e833496c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_requests
    ADD CONSTRAINT fk_rails_82e833496c FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: operator_pay_batch_lines fk_rails_830d94e128; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batch_lines
    ADD CONSTRAINT fk_rails_830d94e128 FOREIGN KEY (approved_by_id) REFERENCES public.users(id);


--
-- Name: dashboard_layouts fk_rails_8420f04d85; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_layouts
    ADD CONSTRAINT fk_rails_8420f04d85 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: pay_rate_plan_vehicle_types fk_rails_84454fa0ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_plan_vehicle_types
    ADD CONSTRAINT fk_rails_84454fa0ca FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: client_bookable_vehicle_types fk_rails_84858ddac7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_bookable_vehicle_types
    ADD CONSTRAINT fk_rails_84858ddac7 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: bookings fk_rails_84f4389273; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT fk_rails_84f4389273 FOREIGN KEY (client_site_id) REFERENCES public.client_sites(id);


--
-- Name: school_bills fk_rails_850c429bc8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT fk_rails_850c429bc8 FOREIGN KEY (recorded_by_id) REFERENCES public.users(id);


--
-- Name: driver_pay_month_runs fk_rails_8533cafd57; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_month_runs
    ADD CONSTRAINT fk_rails_8533cafd57 FOREIGN KEY (driver_pay_month_id) REFERENCES public.driver_pay_months(id);


--
-- Name: school_bills fk_rails_8590ef6af4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT fk_rails_8590ef6af4 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rate_card_vehicle_types fk_rails_85cc5e4960; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_vehicle_types
    ADD CONSTRAINT fk_rails_85cc5e4960 FOREIGN KEY (rate_card_id) REFERENCES public.rate_cards(id);


--
-- Name: school_bills fk_rails_85cdb6c2c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT fk_rails_85cdb6c2c4 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: student_attendances fk_rails_8663610681; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT fk_rails_8663610681 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: driver_app_sessions fk_rails_86c6dfbab4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_app_sessions
    ADD CONSTRAINT fk_rails_86c6dfbab4 FOREIGN KEY (tracking_device_id) REFERENCES public.tracking_devices(id) ON DELETE SET NULL;


--
-- Name: school_route_prices fk_rails_8722f2df7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_prices
    ADD CONSTRAINT fk_rails_8722f2df7d FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: school_route_riders fk_rails_874ac4e9d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_riders
    ADD CONSTRAINT fk_rails_874ac4e9d0 FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id) ON DELETE CASCADE;


--
-- Name: tracking_links fk_rails_87b1845cfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_links
    ADD CONSTRAINT fk_rails_87b1845cfa FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rate_card_rates fk_rails_87c7f6dfd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_rates
    ADD CONSTRAINT fk_rails_87c7f6dfd1 FOREIGN KEY (rate_card_period_id) REFERENCES public.rate_card_periods(id);


--
-- Name: operator_pay_payments fk_rails_87d55a2039; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_payments
    ADD CONSTRAINT fk_rails_87d55a2039 FOREIGN KEY (recorded_by_id) REFERENCES public.users(id);


--
-- Name: user_notification_preferences fk_rails_87f779f968; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notification_preferences
    ADD CONSTRAINT fk_rails_87f779f968 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: school_registrations fk_rails_8812ff182e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_registrations
    ADD CONSTRAINT fk_rails_8812ff182e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: tracking_devices fk_rails_88bfb09fdc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_devices
    ADD CONSTRAINT fk_rails_88bfb09fdc FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: trip_runs fk_rails_898fb491b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_runs
    ADD CONSTRAINT fk_rails_898fb491b0 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_invoices fk_rails_89c2c37d58; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT fk_rails_89c2c37d58 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_billing_contacts fk_rails_89d66f4405; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_billing_contacts
    ADD CONSTRAINT fk_rails_89d66f4405 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fuel_entries fk_rails_8a734d88b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_entries
    ADD CONSTRAINT fk_rails_8a734d88b7 FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: school_attendant_policies fk_rails_8ab04930a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_attendant_policies
    ADD CONSTRAINT fk_rails_8ab04930a8 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: drivers fk_rails_8abb0221b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT fk_rails_8abb0221b3 FOREIGN KEY (last_vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: driver_kyc_profiles fk_rails_8b0f8e0f1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_kyc_profiles
    ADD CONSTRAINT fk_rails_8b0f8e0f1e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: pay_rate_periods fk_rails_8b62945b80; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_periods
    ADD CONSTRAINT fk_rails_8b62945b80 FOREIGN KEY (pay_rate_plan_id) REFERENCES public.pay_rate_plans(id);


--
-- Name: school_route_prices fk_rails_8b7a5293c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_prices
    ADD CONSTRAINT fk_rails_8b7a5293c3 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_riders fk_rails_8bceea732c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_riders
    ADD CONSTRAINT fk_rails_8bceea732c FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: rate_card_distance_bands fk_rails_8c3a1eb62d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_distance_bands
    ADD CONSTRAINT fk_rails_8c3a1eb62d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: tracking_links fk_rails_8c76a19f97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_links
    ADD CONSTRAINT fk_rails_8c76a19f97 FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: school_route_vehicle_changes fk_rails_8ca2c207fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_vehicle_changes
    ADD CONSTRAINT fk_rails_8ca2c207fb FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id);


--
-- Name: notices fk_rails_8cba993083; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT fk_rails_8cba993083 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: tracking_links fk_rails_8ce56161a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_links
    ADD CONSTRAINT fk_rails_8ce56161a7 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: portal_jwts fk_rails_8ce90c0d23; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_jwts
    ADD CONSTRAINT fk_rails_8ce90c0d23 FOREIGN KEY (client_user_id) REFERENCES public.client_users(id);


--
-- Name: rate_card_periods fk_rails_8e1854beb1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_periods
    ADD CONSTRAINT fk_rails_8e1854beb1 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: route_charges fk_rails_8ee602995e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_charges
    ADD CONSTRAINT fk_rails_8ee602995e FOREIGN KEY (carried_from_id) REFERENCES public.route_charges(id) ON DELETE SET NULL;


--
-- Name: stop_photo_submissions fk_rails_8fa7cf382c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_submissions
    ADD CONSTRAINT fk_rails_8fa7cf382c FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_route_stops fk_rails_8fc087f0bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_stops
    ADD CONSTRAINT fk_rails_8fc087f0bc FOREIGN KEY (stop_id) REFERENCES public.stops(id);


--
-- Name: bus_requests fk_rails_90abea8f9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_90abea8f9e FOREIGN KEY (confirmed_by_id) REFERENCES public.users(id);


--
-- Name: client_users fk_rails_91818ac2d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_users
    ADD CONSTRAINT fk_rails_91818ac2d3 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: bus_requests fk_rails_91a9174dce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_91a9174dce FOREIGN KEY (quoted_by_id) REFERENCES public.users(id);


--
-- Name: cca_bookings fk_rails_91feeb3dbf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_bookings
    ADD CONSTRAINT fk_rails_91feeb3dbf FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: pay_schemes fk_rails_9259e89e54; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_schemes
    ADD CONSTRAINT fk_rails_9259e89e54 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: tracking_links fk_rails_928a72914d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracking_links
    ADD CONSTRAINT fk_rails_928a72914d FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: driver_pay_schemes fk_rails_92d083cfce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_schemes
    ADD CONSTRAINT fk_rails_92d083cfce FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fuel_alerts fk_rails_92f9647b19; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_alerts
    ADD CONSTRAINT fk_rails_92f9647b19 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: school_bus_size_rates fk_rails_95c2f456a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bus_size_rates
    ADD CONSTRAINT fk_rails_95c2f456a3 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: cca_off_days fk_rails_95e609eb73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_off_days
    ADD CONSTRAINT fk_rails_95e609eb73 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_users fk_rails_95ee319de8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_users
    ADD CONSTRAINT fk_rails_95ee319de8 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: booking_trip_standbys fk_rails_9626e45e94; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_standbys
    ADD CONSTRAINT fk_rails_9626e45e94 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: discover_placements fk_rails_963a0fd0d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discover_placements
    ADD CONSTRAINT fk_rails_963a0fd0d8 FOREIGN KEY (discover_advertiser_id) REFERENCES public.discover_advertisers(id);


--
-- Name: pay_simulator_templates fk_rails_967b54c2cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_simulator_templates
    ADD CONSTRAINT fk_rails_967b54c2cc FOREIGN KEY (pay_scheme_id) REFERENCES public.pay_schemes(id);


--
-- Name: school_route_stops fk_rails_96d4bf9a94; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_stops
    ADD CONSTRAINT fk_rails_96d4bf9a94 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_run_slots fk_rails_97628a907d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_slots
    ADD CONSTRAINT fk_rails_97628a907d FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: client_users fk_rails_980789d192; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_users
    ADD CONSTRAINT fk_rails_980789d192 FOREIGN KEY (portal_account_id) REFERENCES public.portal_accounts(id);


--
-- Name: bus_request_events fk_rails_9812d6617a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_events
    ADD CONSTRAINT fk_rails_9812d6617a FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: driver_vehicle_types fk_rails_985765b1a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_vehicle_types
    ADD CONSTRAINT fk_rails_985765b1a5 FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: notices fk_rails_98a64c4856; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT fk_rails_98a64c4856 FOREIGN KEY (notice_template_id) REFERENCES public.notice_templates(id);


--
-- Name: booking_trips fk_rails_996165e4e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trips
    ADD CONSTRAINT fk_rails_996165e4e6 FOREIGN KEY (approved_by_id) REFERENCES public.users(id);


--
-- Name: registration_messages fk_rails_9978f4bf2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registration_messages
    ADD CONSTRAINT fk_rails_9978f4bf2c FOREIGN KEY (school_registration_id) REFERENCES public.school_registrations(id) ON DELETE CASCADE;


--
-- Name: booking_cancel_requests fk_rails_9a3da2831f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_cancel_requests
    ADD CONSTRAINT fk_rails_9a3da2831f FOREIGN KEY (booking_trip_id) REFERENCES public.booking_trips(id);


--
-- Name: portal_jwts fk_rails_9a7d4e6084; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_jwts
    ADD CONSTRAINT fk_rails_9a7d4e6084 FOREIGN KEY (portal_account_id) REFERENCES public.portal_accounts(id);


--
-- Name: school_payment_methods fk_rails_9a94ffc4fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_payment_methods
    ADD CONSTRAINT fk_rails_9a94ffc4fa FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: trip_vehicle_slots fk_rails_9acaff659a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_slots
    ADD CONSTRAINT fk_rails_9acaff659a FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: rider_assignments fk_rails_9b1ba1bbec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT fk_rails_9b1ba1bbec FOREIGN KEY (school_plan_id) REFERENCES public.school_plans(id) ON DELETE SET NULL;


--
-- Name: fuel_entries fk_rails_9b1c60aef0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_entries
    ADD CONSTRAINT fk_rails_9b1c60aef0 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: trip_assignments fk_rails_9c242e626f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT fk_rails_9c242e626f FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: trip_stops fk_rails_9ce78f41b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stops
    ADD CONSTRAINT fk_rails_9ce78f41b8 FOREIGN KEY (client_site_id) REFERENCES public.client_sites(id);


--
-- Name: client_invoices fk_rails_9d09f0fe78; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT fk_rails_9d09f0fe78 FOREIGN KEY (voided_by_id) REFERENCES public.users(id);


--
-- Name: bus_requests fk_rails_9d7b245dcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_9d7b245dcf FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE SET NULL;


--
-- Name: school_route_vehicle_changes fk_rails_9e97c8ef71; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_vehicle_changes
    ADD CONSTRAINT fk_rails_9e97c8ef71 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: cca_bookings fk_rails_9eaac5b735; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_bookings
    ADD CONSTRAINT fk_rails_9eaac5b735 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: school_payment_methods fk_rails_9ed5f00bbb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_payment_methods
    ADD CONSTRAINT fk_rails_9ed5f00bbb FOREIGN KEY (bank_id) REFERENCES public.banks(id);


--
-- Name: feasibility_fare_tiers fk_rails_9f50b88b38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_fare_tiers
    ADD CONSTRAINT fk_rails_9f50b88b38 FOREIGN KEY (feasibility_study_id) REFERENCES public.feasibility_studies(id) ON DELETE CASCADE;


--
-- Name: booking_trips fk_rails_9f9e0397f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trips
    ADD CONSTRAINT fk_rails_9f9e0397f5 FOREIGN KEY (booking_day_id) REFERENCES public.booking_days(id);


--
-- Name: trips fk_rails_9fca5ad5f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_9fca5ad5f4 FOREIGN KEY (client_end_customer_id) REFERENCES public.client_end_customers(id);


--
-- Name: driver_app_sessions fk_rails_a0768c3988; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_app_sessions
    ADD CONSTRAINT fk_rails_a0768c3988 FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: routing_runs fk_rails_a097bc0081; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_runs
    ADD CONSTRAINT fk_rails_a097bc0081 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: school_bill_lines fk_rails_a28ab5a28b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bill_lines
    ADD CONSTRAINT fk_rails_a28ab5a28b FOREIGN KEY (school_bill_id) REFERENCES public.school_bills(id) ON DELETE CASCADE;


--
-- Name: client_invoices fk_rails_a2bcdfa04a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT fk_rails_a2bcdfa04a FOREIGN KEY (invoice_id) REFERENCES public.client_invoices(id);


--
-- Name: notice_runs fk_rails_a2f4db88c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_runs
    ADD CONSTRAINT fk_rails_a2f4db88c7 FOREIGN KEY (notice_id) REFERENCES public.notices(id);


--
-- Name: vehicle_log_cards fk_rails_a3696710b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_log_cards
    ADD CONSTRAINT fk_rails_a3696710b4 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: rate_card_vehicle_types fk_rails_a4105c7766; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_vehicle_types
    ADD CONSTRAINT fk_rails_a4105c7766 FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: pay_bonus_schemes fk_rails_a46a0c4cdb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_schemes
    ADD CONSTRAINT fk_rails_a46a0c4cdb FOREIGN KEY (pay_bonus_id) REFERENCES public.pay_bonuses(id);


--
-- Name: booking_trip_changes fk_rails_a4a866a13f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_changes
    ADD CONSTRAINT fk_rails_a4a866a13f FOREIGN KEY (changed_by_id) REFERENCES public.users(id);


--
-- Name: vehicle_insurance_policies fk_rails_a4dbba77e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_insurance_policies
    ADD CONSTRAINT fk_rails_a4dbba77e2 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rate_card_periods fk_rails_a52e0fe064; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_periods
    ADD CONSTRAINT fk_rails_a52e0fe064 FOREIGN KEY (rate_card_id) REFERENCES public.rate_cards(id);


--
-- Name: rider_datasets fk_rails_a55c4885a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rider_datasets
    ADD CONSTRAINT fk_rails_a55c4885a5 FOREIGN KEY (uploaded_by_id) REFERENCES public.users(id);


--
-- Name: cca_ride_settings fk_rails_a79cb2fd59; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_ride_settings
    ADD CONSTRAINT fk_rails_a79cb2fd59 FOREIGN KEY (saved_by_id) REFERENCES public.users(id);


--
-- Name: user_notification_preferences fk_rails_a79fb952e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notification_preferences
    ADD CONSTRAINT fk_rails_a79fb952e9 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fuel_alerts fk_rails_a7ef6fc992; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_alerts
    ADD CONSTRAINT fk_rails_a7ef6fc992 FOREIGN KEY (fuel_entry_id) REFERENCES public.fuel_entries(id) ON DELETE CASCADE;


--
-- Name: school_route_replacements fk_rails_a863561bcb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_replacements
    ADD CONSTRAINT fk_rails_a863561bcb FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: booking_trip_vehicles fk_rails_a8aaa68933; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trip_vehicles
    ADD CONSTRAINT fk_rails_a8aaa68933 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: bookings fk_rails_a90442a02f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT fk_rails_a90442a02f FOREIGN KEY (client_end_customer_id) REFERENCES public.client_end_customers(id);


--
-- Name: driver_point_lots fk_rails_a96e912ebb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_lots
    ADD CONSTRAINT fk_rails_a96e912ebb FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_attendant_policies fk_rails_a9f34184b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_attendant_policies
    ADD CONSTRAINT fk_rails_a9f34184b0 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: trips fk_rails_aa53ce8922; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_aa53ce8922 FOREIGN KEY (client_site_id) REFERENCES public.client_sites(id);


--
-- Name: notice_deliveries fk_rails_aaa115d010; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_deliveries
    ADD CONSTRAINT fk_rails_aaa115d010 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: attendants fk_rails_abeb108c69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendants
    ADD CONSTRAINT fk_rails_abeb108c69 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rate_card_rates fk_rails_abfdeef03a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_rates
    ADD CONSTRAINT fk_rails_abfdeef03a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: student_attendances fk_rails_acef7d2f7c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT fk_rails_acef7d2f7c FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: school_route_riders fk_rails_ad2c513880; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_riders
    ADD CONSTRAINT fk_rails_ad2c513880 FOREIGN KEY (school_route_stop_id) REFERENCES public.school_route_stops(id) ON DELETE CASCADE;


--
-- Name: school_bills fk_rails_ad736e060c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bills
    ADD CONSTRAINT fk_rails_ad736e060c FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id);


--
-- Name: notification_emails fk_rails_adfef0df41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_emails
    ADD CONSTRAINT fk_rails_adfef0df41 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: feasibility_scenarios fk_rails_ae63d6ab93; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_scenarios
    ADD CONSTRAINT fk_rails_ae63d6ab93 FOREIGN KEY (feasibility_study_id) REFERENCES public.feasibility_studies(id) ON DELETE CASCADE;


--
-- Name: trip_attachments fk_rails_aeee2a4ae8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_attachments
    ADD CONSTRAINT fk_rails_aeee2a4ae8 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_invoice_payments fk_rails_af75035153; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_payments
    ADD CONSTRAINT fk_rails_af75035153 FOREIGN KEY (recorded_by_id) REFERENCES public.users(id);


--
-- Name: family_guardians fk_rails_afc44cd0f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_guardians
    ADD CONSTRAINT fk_rails_afc44cd0f6 FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;


--
-- Name: pay_scheme_route_bands fk_rails_aff708dd9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_scheme_route_bands
    ADD CONSTRAINT fk_rails_aff708dd9c FOREIGN KEY (pay_scheme_id) REFERENCES public.pay_schemes(id);


--
-- Name: operator_cost_overrides fk_rails_b01860eee3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_cost_overrides
    ADD CONSTRAINT fk_rails_b01860eee3 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: calendar_days fk_rails_b1b3428a67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_days
    ADD CONSTRAINT fk_rails_b1b3428a67 FOREIGN KEY (calendar_id) REFERENCES public.calendars(id);


--
-- Name: replacements fk_rails_b1c12c54fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_b1c12c54fa FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: client_sites fk_rails_b37d01fbb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_sites
    ADD CONSTRAINT fk_rails_b37d01fbb6 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: vehicles fk_rails_b3d1a297d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_rails_b3d1a297d3 FOREIGN KEY (operator_id) REFERENCES public.operators(id);


--
-- Name: stop_photo_requests fk_rails_b3dabb3200; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_requests
    ADD CONSTRAINT fk_rails_b3dabb3200 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: route_list_versions fk_rails_b41fef6b45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_versions
    ADD CONSTRAINT fk_rails_b41fef6b45 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: bus_request_events fk_rails_b4e716e28d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_events
    ADD CONSTRAINT fk_rails_b4e716e28d FOREIGN KEY (bus_request_id) REFERENCES public.bus_requests(id) ON DELETE CASCADE;


--
-- Name: notices fk_rails_b525c326d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notices
    ADD CONSTRAINT fk_rails_b525c326d2 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: occurrence_correction_logs fk_rails_b5dd4d59e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_logs
    ADD CONSTRAINT fk_rails_b5dd4d59e5 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_stops fk_rails_b64dcb03ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_stops
    ADD CONSTRAINT fk_rails_b64dcb03ba FOREIGN KEY (stop_id) REFERENCES public.stops(id);


--
-- Name: school_levels fk_rails_b65a786c56; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_levels
    ADD CONSTRAINT fk_rails_b65a786c56 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_vehicle_requirements fk_rails_b681905d2b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_vehicle_requirements
    ADD CONSTRAINT fk_rails_b681905d2b FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: notice_routes fk_rails_b7213b4c04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_routes
    ADD CONSTRAINT fk_rails_b7213b4c04 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rate_card_ranges fk_rails_b726b9f7b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_ranges
    ADD CONSTRAINT fk_rails_b726b9f7b3 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fuel_alerts fk_rails_b8031930f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_alerts
    ADD CONSTRAINT fk_rails_b8031930f9 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rate_card_amounts fk_rails_b8122cde29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_amounts
    ADD CONSTRAINT fk_rails_b8122cde29 FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: replacements fk_rails_ba22cadbea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_ba22cadbea FOREIGN KEY (original_vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: fare_size_columns fk_rails_bafd03b551; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_size_columns
    ADD CONSTRAINT fk_rails_bafd03b551 FOREIGN KEY (fare_table_id) REFERENCES public.fare_tables(id) ON DELETE CASCADE;


--
-- Name: school_riders fk_rails_bafd250599; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_riders
    ADD CONSTRAINT fk_rails_bafd250599 FOREIGN KEY (rider_dataset_id) REFERENCES public.rider_datasets(id) ON DELETE CASCADE;


--
-- Name: driver_point_deductions fk_rails_bce970e9a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_deductions
    ADD CONSTRAINT fk_rails_bce970e9a3 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicle_type_requests fk_rails_bd39c27353; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_type_requests
    ADD CONSTRAINT fk_rails_bd39c27353 FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: booking_events fk_rails_bd4278e1bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_events
    ADD CONSTRAINT fk_rails_bd4278e1bd FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: driver_invites fk_rails_bd6c59682a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_invites
    ADD CONSTRAINT fk_rails_bd6c59682a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_price_cells fk_rails_bd8ad5021b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_price_cells
    ADD CONSTRAINT fk_rails_bd8ad5021b FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: operator_drivers fk_rails_c0e174bbfd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers
    ADD CONSTRAINT fk_rails_c0e174bbfd FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: client_pickup_points fk_rails_c1f94d7f8e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_pickup_points
    ADD CONSTRAINT fk_rails_c1f94d7f8e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: bookings fk_rails_c1ffabaf4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT fk_rails_c1ffabaf4d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_route_vias fk_rails_c260397e31; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_route_vias
    ADD CONSTRAINT fk_rails_c260397e31 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: pay_rates fk_rails_c308d18fe8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rates
    ADD CONSTRAINT fk_rails_c308d18fe8 FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: pay_schemes fk_rails_c3beb01bb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_schemes
    ADD CONSTRAINT fk_rails_c3beb01bb4 FOREIGN KEY (pay_rate_plan_id) REFERENCES public.pay_rate_plans(id);


--
-- Name: school_route_replacements fk_rails_c4ca6066b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_replacements
    ADD CONSTRAINT fk_rails_c4ca6066b6 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_run_times fk_rails_c5027d0a2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_times
    ADD CONSTRAINT fk_rails_c5027d0a2d FOREIGN KEY (trip_stop_id) REFERENCES public.trip_stops(id);


--
-- Name: pay_rate_plan_vehicle_types fk_rails_c5bdf0ba03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_plan_vehicle_types
    ADD CONSTRAINT fk_rails_c5bdf0ba03 FOREIGN KEY (pay_rate_plan_id) REFERENCES public.pay_rate_plans(id);


--
-- Name: pay_bonus_drivers fk_rails_c5d14816d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_drivers
    ADD CONSTRAINT fk_rails_c5d14816d1 FOREIGN KEY (pay_bonus_id) REFERENCES public.pay_bonuses(id);


--
-- Name: external_vehicle_share_links fk_rails_c5e52076c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_share_links
    ADD CONSTRAINT fk_rails_c5e52076c2 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: external_vehicle_submissions fk_rails_c5ef312f03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_submissions
    ADD CONSTRAINT fk_rails_c5ef312f03 FOREIGN KEY (share_link_id) REFERENCES public.external_vehicle_share_links(id);


--
-- Name: plan_comments fk_rails_c61ef2fde6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_comments
    ADD CONSTRAINT fk_rails_c61ef2fde6 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_assignments fk_rails_c76d392bae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT fk_rails_c76d392bae FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: disabled_vehicle_types fk_rails_c7fbbd90aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_vehicle_types
    ADD CONSTRAINT fk_rails_c7fbbd90aa FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: rate_card_vehicle_types fk_rails_c851d0b0a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_vehicle_types
    ADD CONSTRAINT fk_rails_c851d0b0a8 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: stops fk_rails_c8abb56843; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stops
    ADD CONSTRAINT fk_rails_c8abb56843 FOREIGN KEY (requested_by_id) REFERENCES public.users(id);


--
-- Name: family_riders fk_rails_c9fff9dbf4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.family_riders
    ADD CONSTRAINT fk_rails_c9fff9dbf4 FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE CASCADE;


--
-- Name: rate_card_amounts fk_rails_ca10ae8d37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_amounts
    ADD CONSTRAINT fk_rails_ca10ae8d37 FOREIGN KEY (rate_card_id) REFERENCES public.rate_cards(id);


--
-- Name: driver_pay_schemes fk_rails_ca60389145; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_schemes
    ADD CONSTRAINT fk_rails_ca60389145 FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: discover_placements fk_rails_ca8fbc2d2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discover_placements
    ADD CONSTRAINT fk_rails_ca8fbc2d2c FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: dashboard_layouts fk_rails_cabe02f143; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_layouts
    ADD CONSTRAINT fk_rails_cabe02f143 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: vehicle_type_requests fk_rails_cb77354afc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_type_requests
    ADD CONSTRAINT fk_rails_cb77354afc FOREIGN KEY (requested_by_id) REFERENCES public.users(id);


--
-- Name: trip_run_slots fk_rails_cb8b2ea471; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_run_slots
    ADD CONSTRAINT fk_rails_cb8b2ea471 FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: route_charges fk_rails_cb8df922c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_charges
    ADD CONSTRAINT fk_rails_cb8df922c2 FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id) ON DELETE SET NULL;


--
-- Name: operators fk_rails_cbbe17d323; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators
    ADD CONSTRAINT fk_rails_cbbe17d323 FOREIGN KEY (bank_id) REFERENCES public.banks(id);


--
-- Name: client_invoice_line_runs fk_rails_cc2332c40f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_line_runs
    ADD CONSTRAINT fk_rails_cc2332c40f FOREIGN KEY (client_invoice_line_id) REFERENCES public.client_invoice_lines(id);


--
-- Name: vehicle_loan_payments fk_rails_cc96c60159; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_loan_payments
    ADD CONSTRAINT fk_rails_cc96c60159 FOREIGN KEY (recorded_by_id) REFERENCES public.users(id);


--
-- Name: plan_comments fk_rails_ccb4ff077f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_comments
    ADD CONSTRAINT fk_rails_ccb4ff077f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: finance_approvers fk_rails_cd2018e937; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_approvers
    ADD CONSTRAINT fk_rails_cd2018e937 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: stop_photo_submissions fk_rails_cda854c3c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stop_photo_submissions
    ADD CONSTRAINT fk_rails_cda854c3c1 FOREIGN KEY (stop_photo_request_id) REFERENCES public.stop_photo_requests(id) ON DELETE CASCADE;


--
-- Name: route_charges fk_rails_ce160510cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_charges
    ADD CONSTRAINT fk_rails_ce160510cf FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: routing_runs fk_rails_cf772b365e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_runs
    ADD CONSTRAINT fk_rails_cf772b365e FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: bus_requests fk_rails_cf90080688; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_requests
    ADD CONSTRAINT fk_rails_cf90080688 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: occurrence_corrections fk_rails_cfc2b2ca6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_corrections
    ADD CONSTRAINT fk_rails_cfc2b2ca6a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: policy_reminders fk_rails_d0b861de67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_reminders
    ADD CONSTRAINT fk_rails_d0b861de67 FOREIGN KEY (school_policy_version_id) REFERENCES public.school_policy_versions(id) ON DELETE CASCADE;


--
-- Name: fuel_entries fk_rails_d1d3e6262d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_entries
    ADD CONSTRAINT fk_rails_d1d3e6262d FOREIGN KEY (document_read_id) REFERENCES public.document_reads(id);


--
-- Name: pay_rate_period_ranges fk_rails_d27459b6a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_rate_period_ranges
    ADD CONSTRAINT fk_rails_d27459b6a2 FOREIGN KEY (pay_rate_period_id) REFERENCES public.pay_rate_periods(id);


--
-- Name: school_plans fk_rails_d314d9ac9b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plans
    ADD CONSTRAINT fk_rails_d314d9ac9b FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: school_special_days fk_rails_d321d3b0cd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_special_days
    ADD CONSTRAINT fk_rails_d321d3b0cd FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: occurrence_notes fk_rails_d3db1b7120; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_notes
    ADD CONSTRAINT fk_rails_d3db1b7120 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: company_lead_domains fk_rails_d43b77cef7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_lead_domains
    ADD CONSTRAINT fk_rails_d43b77cef7 FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: occurrence_correction_logs fk_rails_d46eac2cb2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_logs
    ADD CONSTRAINT fk_rails_d46eac2cb2 FOREIGN KEY (occurrence_correction_id) REFERENCES public.occurrence_corrections(id);


--
-- Name: driver_vehicle_types fk_rails_d471a5a82f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_vehicle_types
    ADD CONSTRAINT fk_rails_d471a5a82f FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: routing_runs fk_rails_d4c1dbd3b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_runs
    ADD CONSTRAINT fk_rails_d4c1dbd3b1 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_route_vehicle_changes fk_rails_d4f0c07d2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_vehicle_changes
    ADD CONSTRAINT fk_rails_d4f0c07d2c FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: fare_tier_sizes fk_rails_d5558ca58a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tier_sizes
    ADD CONSTRAINT fk_rails_d5558ca58a FOREIGN KEY (fare_tier_id) REFERENCES public.fare_tiers(id) ON DELETE CASCADE;


--
-- Name: external_vehicle_submissions fk_rails_d59da55e0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_submissions
    ADD CONSTRAINT fk_rails_d59da55e0c FOREIGN KEY (decided_by_id) REFERENCES public.users(id);


--
-- Name: fare_tables fk_rails_d5ab6ad4af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_tables
    ADD CONSTRAINT fk_rails_d5ab6ad4af FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: school_operator_pays fk_rails_d5b79a03f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_operator_pays
    ADD CONSTRAINT fk_rails_d5b79a03f2 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: pay_bonuses fk_rails_d5f53ac59a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonuses
    ADD CONSTRAINT fk_rails_d5f53ac59a FOREIGN KEY (locked_by_id) REFERENCES public.users(id);


--
-- Name: vehicle_live_positions fk_rails_d667122483; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_live_positions
    ADD CONSTRAINT fk_rails_d667122483 FOREIGN KEY (tracking_device_id) REFERENCES public.tracking_devices(id) ON DELETE SET NULL;


--
-- Name: vehicle_financials fk_rails_d6cf34deec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_financials
    ADD CONSTRAINT fk_rails_d6cf34deec FOREIGN KEY (document_read_id) REFERENCES public.document_reads(id);


--
-- Name: pay_bonus_schemes fk_rails_d7a22324db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonus_schemes
    ADD CONSTRAINT fk_rails_d7a22324db FOREIGN KEY (pay_scheme_id) REFERENCES public.pay_schemes(id);


--
-- Name: client_invoice_lines fk_rails_d850b449ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoice_lines
    ADD CONSTRAINT fk_rails_d850b449ba FOREIGN KEY (client_invoice_id) REFERENCES public.client_invoices(id);


--
-- Name: companies fk_rails_d9035ba026; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT fk_rails_d9035ba026 FOREIGN KEY (country_set_by_id) REFERENCES public.users(id);


--
-- Name: clients fk_rails_db0f958971; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT fk_rails_db0f958971 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: route_list_version_stops fk_rails_db97e3e992; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_version_stops
    ADD CONSTRAINT fk_rails_db97e3e992 FOREIGN KEY (route_list_version_id) REFERENCES public.route_list_versions(id);


--
-- Name: vehicle_loan_payments fk_rails_dc3bc2a5c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_loan_payments
    ADD CONSTRAINT fk_rails_dc3bc2a5c6 FOREIGN KEY (vehicle_financial_id) REFERENCES public.vehicle_financials(id);


--
-- Name: notice_runs fk_rails_dc6a6d3ca5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_runs
    ADD CONSTRAINT fk_rails_dc6a6d3ca5 FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: school_route_prices fk_rails_dcf08ca971; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_prices
    ADD CONSTRAINT fk_rails_dcf08ca971 FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id) ON DELETE CASCADE;


--
-- Name: client_bookable_vehicle_types fk_rails_dd12091845; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_bookable_vehicle_types
    ADD CONSTRAINT fk_rails_dd12091845 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_routes fk_rails_dd7b14bd9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_routes
    ADD CONSTRAINT fk_rails_dd7b14bd9e FOREIGN KEY (school_plan_id) REFERENCES public.school_plans(id);


--
-- Name: route_list_version_students fk_rails_de6ce64979; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_version_students
    ADD CONSTRAINT fk_rails_de6ce64979 FOREIGN KEY (route_list_version_stop_id) REFERENCES public.route_list_version_stops(id);


--
-- Name: rate_card_distance_bands fk_rails_df0e5761d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card_distance_bands
    ADD CONSTRAINT fk_rails_df0e5761d1 FOREIGN KEY (rate_card_id) REFERENCES public.rate_cards(id);


--
-- Name: driver_point_lots fk_rails_e0316fb9f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_lots
    ADD CONSTRAINT fk_rails_e0316fb9f8 FOREIGN KEY (pay_bonus_id) REFERENCES public.pay_bonuses(id);


--
-- Name: trip_route_vias fk_rails_e10b4b7e66; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_route_vias
    ADD CONSTRAINT fk_rails_e10b4b7e66 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: client_pickup_points fk_rails_e18d6f67d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_pickup_points
    ADD CONSTRAINT fk_rails_e18d6f67d0 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: operator_pay_payments fk_rails_e1eca8db0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_payments
    ADD CONSTRAINT fk_rails_e1eca8db0b FOREIGN KEY (operator_pay_batch_operator_id) REFERENCES public.operator_pay_batch_operators(id);


--
-- Name: maintenance_visits fk_rails_e258c431fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_visits
    ADD CONSTRAINT fk_rails_e258c431fa FOREIGN KEY (workshop_id) REFERENCES public.workshops(id);


--
-- Name: finance_settings fk_rails_e2794f23ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finance_settings
    ADD CONSTRAINT fk_rails_e2794f23ce FOREIGN KEY (locked_by_id) REFERENCES public.users(id);


--
-- Name: trip_assignments fk_rails_e2afd36d07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT fk_rails_e2afd36d07 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: operator_pay_batches fk_rails_e42544b8c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_pay_batches
    ADD CONSTRAINT fk_rails_e42544b8c9 FOREIGN KEY (bank_file_by_id) REFERENCES public.users(id);


--
-- Name: booking_trips fk_rails_e4f26cb643; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trips
    ADD CONSTRAINT fk_rails_e4f26cb643 FOREIGN KEY (rejected_by_id) REFERENCES public.users(id);


--
-- Name: setup_locks fk_rails_e64267a8c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setup_locks
    ADD CONSTRAINT fk_rails_e64267a8c4 FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: booking_trips fk_rails_e6503b9c7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_trips
    ADD CONSTRAINT fk_rails_e6503b9c7e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: booking_cancel_requests fk_rails_e7a07b46b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_cancel_requests
    ADD CONSTRAINT fk_rails_e7a07b46b8 FOREIGN KEY (resolved_by_id) REFERENCES public.users(id);


--
-- Name: pay_bonuses fk_rails_e7d50d3571; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_bonuses
    ADD CONSTRAINT fk_rails_e7d50d3571 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: route_list_versions fk_rails_e82636ad7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_versions
    ADD CONSTRAINT fk_rails_e82636ad7e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fuel_entries fk_rails_e888434f87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_entries
    ADD CONSTRAINT fk_rails_e888434f87 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: operator_drivers fk_rails_e8cdb98e97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers
    ADD CONSTRAINT fk_rails_e8cdb98e97 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: operators fk_rails_e9075effc2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators
    ADD CONSTRAINT fk_rails_e9075effc2 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: pay_simulator_templates fk_rails_e91a2b6313; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_simulator_templates
    ADD CONSTRAINT fk_rails_e91a2b6313 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_levels fk_rails_e91dd6382f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_levels
    ADD CONSTRAINT fk_rails_e91dd6382f FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: driver_point_allocations fk_rails_e963a81a27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_allocations
    ADD CONSTRAINT fk_rails_e963a81a27 FOREIGN KEY (driver_point_lot_id) REFERENCES public.driver_point_lots(id);


--
-- Name: vehicle_cost_spike_acks fk_rails_e9725459a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_cost_spike_acks
    ADD CONSTRAINT fk_rails_e9725459a8 FOREIGN KEY (checked_by_id) REFERENCES public.users(id);


--
-- Name: vehicle_log_cards fk_rails_ea1e6bdc96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_log_cards
    ADD CONSTRAINT fk_rails_ea1e6bdc96 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: routing_settings fk_rails_ea850ef1c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routing_settings
    ADD CONSTRAINT fk_rails_ea850ef1c5 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: schools fk_rails_eb67311315; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT fk_rails_eb67311315 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: cca_credits fk_rails_ebbf5e2a69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_credits
    ADD CONSTRAINT fk_rails_ebbf5e2a69 FOREIGN KEY (family_id) REFERENCES public.families(id);


--
-- Name: trip_attachments fk_rails_ebc0d3e350; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_attachments
    ADD CONSTRAINT fk_rails_ebc0d3e350 FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: notice_routes fk_rails_eca92bd2cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notice_routes
    ADD CONSTRAINT fk_rails_eca92bd2cf FOREIGN KEY (notice_id) REFERENCES public.notices(id);


--
-- Name: bus_request_places fk_rails_eccee0db9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus_request_places
    ADD CONSTRAINT fk_rails_eccee0db9e FOREIGN KEY (bus_request_id) REFERENCES public.bus_requests(id) ON DELETE CASCADE;


--
-- Name: vehicle_driver_schedules fk_rails_eccf512042; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT fk_rails_eccf512042 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: operator_drivers fk_rails_ed336030fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers
    ADD CONSTRAINT fk_rails_ed336030fc FOREIGN KEY (last_vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: school_registrations fk_rails_eda4068198; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_registrations
    ADD CONSTRAINT fk_rails_eda4068198 FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: school_bus_size_rates fk_rails_edeaec1a6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_bus_size_rates
    ADD CONSTRAINT fk_rails_edeaec1a6b FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_assignment_slots fk_rails_eeb9f36215; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_assignment_slots
    ADD CONSTRAINT fk_rails_eeb9f36215 FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id);


--
-- Name: driver_invites fk_rails_ef1db98250; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_invites
    ADD CONSTRAINT fk_rails_ef1db98250 FOREIGN KEY (sent_by_id) REFERENCES public.users(id);


--
-- Name: driver_vehicle_types fk_rails_ef5d928024; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_vehicle_types
    ADD CONSTRAINT fk_rails_ef5d928024 FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: vehicle_cost_spike_acks fk_rails_f03f046cfe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_cost_spike_acks
    ADD CONSTRAINT fk_rails_f03f046cfe FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: public_holidays fk_rails_f0671ffc35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_holidays
    ADD CONSTRAINT fk_rails_f0671ffc35 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: plan_comments fk_rails_f08b9a64df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_comments
    ADD CONSTRAINT fk_rails_f08b9a64df FOREIGN KEY (school_plan_id) REFERENCES public.school_plans(id) ON DELETE CASCADE;


--
-- Name: external_vehicle_submissions fk_rails_f0c09ab3d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_submissions
    ADD CONSTRAINT fk_rails_f0c09ab3d0 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: client_sites fk_rails_f13e189478; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_sites
    ADD CONSTRAINT fk_rails_f13e189478 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: drivers fk_rails_f1f5419320; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT fk_rails_f1f5419320 FOREIGN KEY (display_set_by_id) REFERENCES public.users(id);


--
-- Name: fare_bus_rates fk_rails_f1fd2de355; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_bus_rates
    ADD CONSTRAINT fk_rails_f1fd2de355 FOREIGN KEY (fare_table_id) REFERENCES public.fare_tables(id) ON DELETE CASCADE;


--
-- Name: pay_schemes fk_rails_f22e12e1ef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_schemes
    ADD CONSTRAINT fk_rails_f22e12e1ef FOREIGN KEY (locked_by_id) REFERENCES public.users(id);


--
-- Name: setup_locks fk_rails_f22e2709bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setup_locks
    ADD CONSTRAINT fk_rails_f22e2709bc FOREIGN KEY (locked_by_id) REFERENCES public.users(id);


--
-- Name: booking_attachments fk_rails_f2d803a27e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_attachments
    ADD CONSTRAINT fk_rails_f2d803a27e FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: external_vehicle_share_links fk_rails_f30a1943c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_vehicle_share_links
    ADD CONSTRAINT fk_rails_f30a1943c8 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: vehicle_finance_entries fk_rails_f3368bb705; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_finance_entries
    ADD CONSTRAINT fk_rails_f3368bb705 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: school_policy_versions fk_rails_f3490479bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_policy_versions
    ADD CONSTRAINT fk_rails_f3490479bd FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: feasibility_bus_prices fk_rails_f351dab122; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feasibility_bus_prices
    ADD CONSTRAINT fk_rails_f351dab122 FOREIGN KEY (feasibility_study_id) REFERENCES public.feasibility_studies(id) ON DELETE CASCADE;


--
-- Name: route_list_version_students fk_rails_f382665b51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_list_version_students
    ADD CONSTRAINT fk_rails_f382665b51 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicle_driver_schedules fk_rails_f38af088ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT fk_rails_f38af088ae FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: driver_pay_months fk_rails_f46ae7821f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_months
    ADD CONSTRAINT fk_rails_f46ae7821f FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: client_invoices fk_rails_f51154a7fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_invoices
    ADD CONSTRAINT fk_rails_f51154a7fe FOREIGN KEY (client_site_id) REFERENCES public.client_sites(id);


--
-- Name: fuel_entries fk_rails_f512993488; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_entries
    ADD CONSTRAINT fk_rails_f512993488 FOREIGN KEY (fuel_company_id) REFERENCES public.fuel_companies(id);


--
-- Name: cca_credits fk_rails_f537469b6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cca_credits
    ADD CONSTRAINT fk_rails_f537469b6b FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: families fk_rails_f579f5619b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.families
    ADD CONSTRAINT fk_rails_f579f5619b FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: calendars fk_rails_f6ad5c8b19; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendars
    ADD CONSTRAINT fk_rails_f6ad5c8b19 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: driver_point_lots fk_rails_f6d38722cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_point_lots
    ADD CONSTRAINT fk_rails_f6d38722cf FOREIGN KEY (awarded_by_id) REFERENCES public.users(id);


--
-- Name: school_route_replacements fk_rails_f7c1a6fbbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_replacements
    ADD CONSTRAINT fk_rails_f7c1a6fbbd FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: trip_stop_students fk_rails_f980f79819; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_stop_students
    ADD CONSTRAINT fk_rails_f980f79819 FOREIGN KEY (trip_stop_id) REFERENCES public.trip_stops(id);


--
-- Name: trip_time_changes fk_rails_f9d4691e24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_time_changes
    ADD CONSTRAINT fk_rails_f9d4691e24 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: operator_drivers fk_rails_f9ed4c3458; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers
    ADD CONSTRAINT fk_rails_f9ed4c3458 FOREIGN KEY (operator_id) REFERENCES public.operators(id);


--
-- Name: replacements fk_rails_fac844f251; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replacements
    ADD CONSTRAINT fk_rails_fac844f251 FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: trips fk_rails_faf15f74e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT fk_rails_faf15f74e8 FOREIGN KEY (calendar_id) REFERENCES public.calendars(id);


--
-- Name: booking_cancel_requests fk_rails_faf9514368; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_cancel_requests
    ADD CONSTRAINT fk_rails_faf9514368 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: fuel_companies fk_rails_fb0ece995a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_companies
    ADD CONSTRAINT fk_rails_fb0ece995a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: occurrence_correction_logs fk_rails_fb71a38135; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.occurrence_correction_logs
    ADD CONSTRAINT fk_rails_fb71a38135 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: driver_pay_months fk_rails_fbbecf700c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_pay_months
    ADD CONSTRAINT fk_rails_fbbecf700c FOREIGN KEY (confirmed_by_id) REFERENCES public.users(id);


--
-- Name: client_user_sites fk_rails_fd7be929e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_user_sites
    ADD CONSTRAINT fk_rails_fd7be929e9 FOREIGN KEY (client_user_id) REFERENCES public.client_users(id);


--
-- Name: route_charges fk_rails_fd7e7a8427; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_charges
    ADD CONSTRAINT fk_rails_fd7e7a8427 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: school_plan_changes fk_rails_fdfb531cc8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_plan_changes
    ADD CONSTRAINT fk_rails_fdfb531cc8 FOREIGN KEY (bus_request_id) REFERENCES public.bus_requests(id) ON DELETE SET NULL;


--
-- Name: school_route_labels fk_rails_fef97aa7b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_route_labels
    ADD CONSTRAINT fk_rails_fef97aa7b9 FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: occurrence_positions occurrence_positions_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.occurrence_positions
    ADD CONSTRAINT occurrence_positions_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_occurrences trip_occurrences_cancelled_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_cancelled_by_id_fkey FOREIGN KEY (cancelled_by_id) REFERENCES public.users(id);


--
-- Name: trip_occurrences trip_occurrences_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: trip_occurrences trip_occurrences_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: trip_occurrences trip_occurrences_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: trip_occurrences trip_occurrences_issue_raised_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_issue_raised_by_id_fkey FOREIGN KEY (issue_raised_by_id) REFERENCES public.users(id);


--
-- Name: trip_occurrences trip_occurrences_operator_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_operator_driver_id_fkey FOREIGN KEY (operator_driver_id) REFERENCES public.operator_drivers(id);


--
-- Name: trip_occurrences trip_occurrences_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.operators(id);


--
-- Name: trip_occurrences trip_occurrences_original_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_original_vehicle_id_fkey FOREIGN KEY (original_vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: trip_occurrences trip_occurrences_replacement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_replacement_id_fkey FOREIGN KEY (replacement_id) REFERENCES public.replacements(id) ON DELETE SET NULL;


--
-- Name: trip_occurrences trip_occurrences_school_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_school_route_id_fkey FOREIGN KEY (school_route_id) REFERENCES public.school_routes(id);


--
-- Name: trip_occurrences trip_occurrences_trip_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_trip_assignment_id_fkey FOREIGN KEY (trip_assignment_id) REFERENCES public.trip_assignments(id) ON DELETE SET NULL;


--
-- Name: trip_occurrences trip_occurrences_trip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- Name: trip_occurrences trip_occurrences_trip_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_trip_run_id_fkey FOREIGN KEY (trip_run_id) REFERENCES public.trip_runs(id) ON DELETE SET NULL;


--
-- Name: trip_occurrences trip_occurrences_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trip_occurrences
    ADD CONSTRAINT trip_occurrences_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261103120000'),
('20261103110200'),
('20261103110100'),
('20261103110000'),
('20261103100200'),
('20261103100100'),
('20261103100000'),
('20261103090000'),
('20261102211000'),
('20261102210000'),
('20261102209600'),
('20261102209500'),
('20261102209400'),
('20261102209300'),
('20261102209200'),
('20261102209100'),
('20261102209000'),
('20261102208000'),
('20261102207000'),
('20261102206000'),
('20261102205000'),
('20261102204000'),
('20261102203000'),
('20261102202000'),
('20261102201000'),
('20261102200000'),
('20261102190000'),
('20261102180000'),
('20261102172000'),
('20261102171000'),
('20261102170000'),
('20261102163000'),
('20261102162000'),
('20261102161100'),
('20261102161000'),
('20261102160000'),
('20261102156000'),
('20261102155000'),
('20261102154000'),
('20261102153000'),
('20261102152000'),
('20261102151000'),
('20261102150000'),
('20261102143000'),
('20261102142000'),
('20261102141300'),
('20261102141200'),
('20261102141100'),
('20261102141000'),
('20261102140000'),
('20261102130300'),
('20261102130200'),
('20261102130100'),
('20261102130000'),
('20261102120200'),
('20261102120100'),
('20261102120000'),
('20261102100000'),
('20261031170000'),
('20261031160000'),
('20261031150000'),
('20261031140100'),
('20261031140000'),
('20261031130200'),
('20261031130100'),
('20261031130000'),
('20261031120200'),
('20261031120100'),
('20261031120000'),
('20261031110000'),
('20261031100000'),
('20261030190100'),
('20261030190000'),
('20261030180200'),
('20261030180100'),
('20261030180000'),
('20261030170000'),
('20261030160000'),
('20261030150200'),
('20261030150100'),
('20261030150000'),
('20261030140000'),
('20261030130200'),
('20261030130100'),
('20261030130000'),
('20261030120100'),
('20261030120000'),
('20261030110100'),
('20261030110000'),
('20261030100100'),
('20261030100000'),
('20261030090300'),
('20261030090200'),
('20261030090100'),
('20261030090050'),
('20261030090000'),
('20261030080000'),
('20261030070200'),
('20261030070100'),
('20261030070000'),
('20261030060100'),
('20261030060000'),
('20261030050300'),
('20261030050200'),
('20261030050100'),
('20261030050000'),
('20261030040100'),
('20261030040000'),
('20261030035409');

