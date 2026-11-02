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
    audited_changes text,
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
    updated_at timestamp(6) without time zone NOT NULL
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
    updated_at timestamp(6) without time zone NOT NULL
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
    updated_at timestamp(6) without time zone NOT NULL
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
    updated_at timestamp(6) without time zone NOT NULL
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
    updated_at timestamp(6) without time zone NOT NULL
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
    updated_at timestamp(6) without time zone NOT NULL
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
    updated_at timestamp(6) without time zone NOT NULL
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
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: solid_queue_batch_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_batch_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    batch_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_batch_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_batch_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_batch_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_batch_executions_id_seq OWNED BY public.solid_queue_batch_executions.id;


--
-- Name: solid_queue_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_batches (
    id bigint NOT NULL,
    active_job_batch_id character varying,
    description character varying,
    on_finish text,
    on_success text,
    on_failure text,
    metadata text,
    total_jobs integer DEFAULT 0 NOT NULL,
    completed_jobs integer DEFAULT 0 NOT NULL,
    failed_jobs integer DEFAULT 0 NOT NULL,
    enqueued_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    failed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_batches_id_seq OWNED BY public.solid_queue_batches.id;


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    concurrency_key character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    class_name character varying NOT NULL,
    arguments text,
    priority integer DEFAULT 0 NOT NULL,
    active_job_id character varying,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    batch_id bigint
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    supervisor_id bigint,
    pid integer NOT NULL,
    hostname character varying,
    metadata text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    task_key character varying NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    key character varying NOT NULL,
    schedule character varying NOT NULL,
    command character varying(2048),
    class_name character varying,
    arguments text,
    queue_name character varying,
    priority integer DEFAULT 0,
    static boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value integer DEFAULT 1 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


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
    updated_at timestamp(6) without time zone NOT NULL
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
    updated_at timestamp(6) without time zone NOT NULL
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
    updated_at timestamp(6) without time zone NOT NULL
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
-- Name: attendants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendants ALTER COLUMN id SET DEFAULT nextval('public.attendants_id_seq'::regclass);


--
-- Name: audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audits ALTER COLUMN id SET DEFAULT nextval('public.audits_id_seq'::regclass);


--
-- Name: calendar_days id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_days ALTER COLUMN id SET DEFAULT nextval('public.calendar_days_id_seq'::regclass);


--
-- Name: calendars id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendars ALTER COLUMN id SET DEFAULT nextval('public.calendars_id_seq'::regclass);


--
-- Name: client_end_customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_end_customers ALTER COLUMN id SET DEFAULT nextval('public.client_end_customers_id_seq'::regclass);


--
-- Name: client_pickup_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_pickup_points ALTER COLUMN id SET DEFAULT nextval('public.client_pickup_points_id_seq'::regclass);


--
-- Name: client_sites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_sites ALTER COLUMN id SET DEFAULT nextval('public.client_sites_id_seq'::regclass);


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: company_sequences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_sequences ALTER COLUMN id SET DEFAULT nextval('public.company_sequences_id_seq'::regclass);


--
-- Name: disabled_vehicle_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_vehicle_types ALTER COLUMN id SET DEFAULT nextval('public.disabled_vehicle_types_id_seq'::regclass);


--
-- Name: drivers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers ALTER COLUMN id SET DEFAULT nextval('public.drivers_id_seq'::regclass);


--
-- Name: operator_drivers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers ALTER COLUMN id SET DEFAULT nextval('public.operator_drivers_id_seq'::regclass);


--
-- Name: operators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators ALTER COLUMN id SET DEFAULT nextval('public.operators_id_seq'::regclass);


--
-- Name: public_holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_holidays ALTER COLUMN id SET DEFAULT nextval('public.public_holidays_id_seq'::regclass);


--
-- Name: solid_queue_batch_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batch_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_batch_executions_id_seq'::regclass);


--
-- Name: solid_queue_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batches ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_batches_id_seq'::regclass);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vehicle_driver_schedules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules ALTER COLUMN id SET DEFAULT nextval('public.vehicle_driver_schedules_id_seq'::regclass);


--
-- Name: vehicle_teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_teams ALTER COLUMN id SET DEFAULT nextval('public.vehicle_teams_id_seq'::regclass);


--
-- Name: vehicle_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_types ALTER COLUMN id SET DEFAULT nextval('public.vehicle_types_id_seq'::regclass);


--
-- Name: vehicles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles ALTER COLUMN id SET DEFAULT nextval('public.vehicles_id_seq'::regclass);


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
-- Name: client_end_customers client_end_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_end_customers
    ADD CONSTRAINT client_end_customers_pkey PRIMARY KEY (id);


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
-- Name: company_sequences company_sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_sequences
    ADD CONSTRAINT company_sequences_pkey PRIMARY KEY (id);


--
-- Name: disabled_vehicle_types disabled_vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_vehicle_types
    ADD CONSTRAINT disabled_vehicle_types_pkey PRIMARY KEY (id);


--
-- Name: drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- Name: operator_drivers operator_drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers
    ADD CONSTRAINT operator_drivers_pkey PRIMARY KEY (id);


--
-- Name: operators operators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operators
    ADD CONSTRAINT operators_pkey PRIMARY KEY (id);


--
-- Name: public_holidays public_holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_holidays
    ADD CONSTRAINT public_holidays_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: solid_queue_batch_executions solid_queue_batch_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batch_executions
    ADD CONSTRAINT solid_queue_batch_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_batches solid_queue_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batches
    ADD CONSTRAINT solid_queue_batches_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicle_driver_schedules vehicle_driver_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT vehicle_driver_schedules_pkey PRIMARY KEY (id);


--
-- Name: vehicle_teams vehicle_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_teams
    ADD CONSTRAINT vehicle_teams_pkey PRIMARY KEY (id);


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
-- Name: associated_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX associated_index ON public.audits USING btree (associated_type, associated_id);


--
-- Name: auditable_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditable_index ON public.audits USING btree (auditable_type, auditable_id, version);


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
-- Name: index_companies_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_companies_on_code ON public.companies USING btree (code);


--
-- Name: index_company_sequences_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_sequences_on_company_id ON public.company_sequences USING btree (company_id);


--
-- Name: index_company_sequences_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_company_sequences_on_company_id_and_name ON public.company_sequences USING btree (company_id, name);


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
-- Name: index_drivers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drivers_on_company_id ON public.drivers USING btree (company_id);


--
-- Name: index_drivers_on_company_id_and_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_drivers_on_company_id_and_phone ON public.drivers USING btree (company_id, phone);


--
-- Name: index_drivers_on_company_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drivers_on_company_id_and_status ON public.drivers USING btree (company_id, status);


--
-- Name: index_operator_drivers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operator_drivers_on_company_id ON public.operator_drivers USING btree (company_id);


--
-- Name: index_operator_drivers_on_company_id_and_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_operator_drivers_on_company_id_and_phone ON public.operator_drivers USING btree (company_id, phone);


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
-- Name: index_public_holidays_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_public_holidays_on_company_id ON public.public_holidays USING btree (company_id);


--
-- Name: index_public_holidays_on_company_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_public_holidays_on_company_id_and_date ON public.public_holidays USING btree (company_id, date);


--
-- Name: index_solid_queue_batch_executions_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_batch_executions_on_batch_id ON public.solid_queue_batch_executions USING btree (batch_id);


--
-- Name: index_solid_queue_batch_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_batch_executions_on_job_id ON public.solid_queue_batch_executions USING btree (job_id);


--
-- Name: index_solid_queue_batches_on_active_job_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_batches_on_active_job_batch_id ON public.solid_queue_batches USING btree (active_job_batch_id);


--
-- Name: index_solid_queue_batches_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_batches_on_finished_at ON public.solid_queue_batches USING btree (finished_at);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_batch_id ON public.solid_queue_jobs USING btree (batch_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_users_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_company_id ON public.users USING btree (company_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_permissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_permissions ON public.users USING gin (permissions);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


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
-- Name: index_vehicle_teams_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicle_teams_on_company_id ON public.vehicle_teams USING btree (company_id);


--
-- Name: index_vehicle_teams_on_company_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vehicle_teams_on_company_id_and_name ON public.vehicle_teams USING btree (company_id, name);


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
-- Name: user_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_index ON public.audits USING btree (user_id, user_type);


--
-- Name: company_sequences fk_rails_10769b2801; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_sequences
    ADD CONSTRAINT fk_rails_10769b2801 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_end_customers fk_rails_1353d28e73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_end_customers
    ADD CONSTRAINT fk_rails_1353d28e73 FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: client_pickup_points fk_rails_168d0a053a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_pickup_points
    ADD CONSTRAINT fk_rails_168d0a053a FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: drivers fk_rails_1ae84e42c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT fk_rails_1ae84e42c0 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_sites fk_rails_206a27dfcd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_sites
    ADD CONSTRAINT fk_rails_206a27dfcd FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: disabled_vehicle_types fk_rails_30090ae9aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_vehicle_types
    ADD CONSTRAINT fk_rails_30090ae9aa FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_types(id);


--
-- Name: vehicles fk_rails_314b522c0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_rails_314b522c0a FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: solid_queue_recurring_executions fk_rails_318a5533ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT fk_rails_318a5533ed FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: calendar_days fk_rails_363537453d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_days
    ADD CONSTRAINT fk_rails_363537453d FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: client_end_customers fk_rails_38fb529cd4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_end_customers
    ADD CONSTRAINT fk_rails_38fb529cd4 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: solid_queue_failed_executions fk_rails_39bbc7a631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT fk_rails_39bbc7a631 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_blocked_executions fk_rails_4cd34e2228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT fk_rails_4cd34e2228 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: vehicle_driver_schedules fk_rails_5d7d8402cd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT fk_rails_5d7d8402cd FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: vehicle_teams fk_rails_620cfa77f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_teams
    ADD CONSTRAINT fk_rails_620cfa77f0 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicles fk_rails_679fe54be7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_rails_679fe54be7 FOREIGN KEY (vehicle_team_id) REFERENCES public.vehicle_teams(id);


--
-- Name: vehicle_driver_schedules fk_rails_745a342283; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT fk_rails_745a342283 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: users fk_rails_7682a3bdfe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_7682a3bdfe FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: solid_queue_batch_executions fk_rails_7c5e073422; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batch_executions
    ADD CONSTRAINT fk_rails_7c5e073422 FOREIGN KEY (batch_id) REFERENCES public.solid_queue_batches(id) ON DELETE CASCADE;


--
-- Name: solid_queue_ready_executions fk_rails_81fcbd66af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT fk_rails_81fcbd66af FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_claimed_executions fk_rails_9cfe4d4944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT fk_rails_9cfe4d4944 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: attendants fk_rails_abeb108c69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendants
    ADD CONSTRAINT fk_rails_abeb108c69 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: calendar_days fk_rails_b1b3428a67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_days
    ADD CONSTRAINT fk_rails_b1b3428a67 FOREIGN KEY (calendar_id) REFERENCES public.calendars(id);


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
-- Name: solid_queue_batch_executions fk_rails_bc9f981155; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batch_executions
    ADD CONSTRAINT fk_rails_bc9f981155 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


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
-- Name: solid_queue_scheduled_executions fk_rails_c4316f352d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT fk_rails_c4316f352d FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: disabled_vehicle_types fk_rails_c7fbbd90aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_vehicle_types
    ADD CONSTRAINT fk_rails_c7fbbd90aa FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: clients fk_rails_db0f958971; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT fk_rails_db0f958971 FOREIGN KEY (company_id) REFERENCES public.companies(id);


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
-- Name: vehicle_driver_schedules fk_rails_eccf512042; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT fk_rails_eccf512042 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: public_holidays fk_rails_f0671ffc35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_holidays
    ADD CONSTRAINT fk_rails_f0671ffc35 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: vehicle_driver_schedules fk_rails_f38af088ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_driver_schedules
    ADD CONSTRAINT fk_rails_f38af088ae FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: calendars fk_rails_f6ad5c8b19; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendars
    ADD CONSTRAINT fk_rails_f6ad5c8b19 FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: operator_drivers fk_rails_f9ed4c3458; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_drivers
    ADD CONSTRAINT fk_rails_f9ed4c3458 FOREIGN KEY (operator_id) REFERENCES public.operators(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261030050300');

