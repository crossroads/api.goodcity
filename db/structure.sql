--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5
-- Dumped by pg_dump version 10.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    id integer NOT NULL,
    flat character varying,
    building character varying,
    street character varying,
    district_id integer,
    addressable_id integer,
    addressable_type character varying,
    address_type character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;


--
-- Name: appointment_slot_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointment_slot_presets (
    id integer NOT NULL,
    day integer,
    hours integer,
    minutes integer,
    quota integer
);


--
-- Name: appointment_slot_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appointment_slot_presets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointment_slot_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appointment_slot_presets_id_seq OWNED BY public.appointment_slot_presets.id;


--
-- Name: appointment_slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointment_slots (
    id integer NOT NULL,
    "timestamp" timestamp with time zone,
    quota integer,
    note character varying DEFAULT ''::character varying
);


--
-- Name: appointment_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appointment_slots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointment_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appointment_slots_id_seq OWNED BY public.appointment_slots.id;


--
-- Name: auth_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_tokens (
    id integer NOT NULL,
    otp_code_expiry timestamp with time zone,
    otp_secret_key character varying,
    user_id integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    otp_auth_key character varying(30)
);


--
-- Name: auth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_tokens_id_seq OWNED BY public.auth_tokens.id;


--
-- Name: beneficiaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beneficiaries (
    id integer NOT NULL,
    identity_type_id integer,
    created_by_id integer,
    identity_number character varying,
    title character varying,
    first_name character varying,
    last_name character varying,
    phone_number character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: beneficiaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.beneficiaries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: beneficiaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.beneficiaries_id_seq OWNED BY public.beneficiaries.id;


--
-- Name: booking_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_types (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    identifier character varying
);


--
-- Name: booking_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_types_id_seq OWNED BY public.booking_types.id;


--
-- Name: boxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.boxes (
    id integer NOT NULL,
    box_number character varying,
    description character varying,
    comments text,
    pallet_id integer,
    stockit_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: boxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.boxes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.boxes_id_seq OWNED BY public.boxes.id;


--
-- Name: braintree_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.braintree_transactions (
    id integer NOT NULL,
    transaction_id character varying,
    customer_id integer,
    amount numeric,
    status character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_success boolean
);


--
-- Name: braintree_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.braintree_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: braintree_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.braintree_transactions_id_seq OWNED BY public.braintree_transactions.id;


--
-- Name: cancellation_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cancellation_reasons (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    visible_to_admin boolean DEFAULT true
);


--
-- Name: cancellation_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cancellation_reasons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cancellation_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cancellation_reasons_id_seq OWNED BY public.cancellation_reasons.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id integer NOT NULL,
    name character varying,
    mobile character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    stockit_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.countries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.countries_id_seq OWNED BY public.countries.id;


--
-- Name: crossroads_transports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crossroads_transports (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    cost integer,
    truck_size double precision,
    is_van_allowed boolean DEFAULT true
);


--
-- Name: crossroads_transports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crossroads_transports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crossroads_transports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crossroads_transports_id_seq OWNED BY public.crossroads_transports.id;


--
-- Name: deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deliveries (
    id integer NOT NULL,
    offer_id integer,
    contact_id integer,
    schedule_id integer,
    delivery_type character varying,
    start timestamp with time zone,
    finish timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    gogovan_order_id integer,
    deleted_at timestamp with time zone
);


--
-- Name: deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deliveries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deliveries_id_seq OWNED BY public.deliveries.id;


--
-- Name: districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.districts (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    territory_id integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    latitude double precision,
    longitude double precision
);


--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.districts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- Name: donor_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.donor_conditions (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: donor_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.donor_conditions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donor_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.donor_conditions_id_seq OWNED BY public.donor_conditions.id;


--
-- Name: gogovan_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gogovan_orders (
    id integer NOT NULL,
    booking_id integer,
    status character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    price double precision,
    driver_name character varying,
    driver_mobile character varying,
    driver_license character varying,
    ggv_uuid character varying,
    completed_at timestamp with time zone
);


--
-- Name: gogovan_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gogovan_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gogovan_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gogovan_orders_id_seq OWNED BY public.gogovan_orders.id;


--
-- Name: gogovan_transports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gogovan_transports (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean DEFAULT false
);


--
-- Name: gogovan_transports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gogovan_transports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gogovan_transports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gogovan_transports_id_seq OWNED BY public.gogovan_transports.id;


--
-- Name: goodcity_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.goodcity_requests (
    id integer NOT NULL,
    quantity integer,
    package_type_id integer,
    order_id integer,
    description text,
    created_by_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: goodcity_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.goodcity_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: goodcity_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.goodcity_requests_id_seq OWNED BY public.goodcity_requests.id;


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holidays (
    id integer NOT NULL,
    holiday timestamp with time zone,
    year integer,
    name character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.holidays_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.holidays_id_seq OWNED BY public.holidays.id;


--
-- Name: identity_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identity_types (
    id integer NOT NULL,
    identifier character varying,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: identity_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.identity_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identity_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.identity_types_id_seq OWNED BY public.identity_types.id;


--
-- Name: images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.images (
    id integer NOT NULL,
    cloudinary_id character varying,
    favourite boolean DEFAULT false,
    item_id integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    angle integer DEFAULT 0,
    imageable_id integer,
    imageable_type character varying
);


--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.images_id_seq OWNED BY public.images.id;


--
-- Name: inventory_numbers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_numbers (
    id integer NOT NULL,
    code character varying
);


--
-- Name: inventory_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_numbers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_numbers_id_seq OWNED BY public.inventory_numbers.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id integer NOT NULL,
    donor_description text,
    state character varying,
    offer_id integer NOT NULL,
    package_type_id integer,
    rejection_reason_id integer,
    reject_reason character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    donor_condition_id integer,
    deleted_at timestamp with time zone,
    rejection_comments text
);


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id integer NOT NULL,
    building character varying,
    area character varying,
    stockit_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    body text,
    sender_id integer,
    is_private boolean DEFAULT false,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    offer_id integer,
    item_id integer
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: offers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offers (
    id integer NOT NULL,
    language character varying,
    state character varying,
    origin character varying,
    stairs boolean,
    parking boolean,
    estimated_size character varying,
    notes text,
    created_by_id integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    submitted_at timestamp with time zone,
    reviewed_by_id integer,
    reviewed_at timestamp with time zone,
    gogovan_transport_id integer,
    crossroads_transport_id integer,
    review_completed_at timestamp with time zone,
    received_at timestamp with time zone,
    delivered_by character varying(30),
    closed_by_id integer,
    cancelled_at timestamp with time zone,
    received_by_id integer,
    start_receiving_at timestamp with time zone,
    cancellation_reason_id integer,
    cancel_reason character varying,
    inactive_at timestamp with time zone,
    saleable boolean DEFAULT false
);


--
-- Name: offers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offers_id_seq OWNED BY public.offers.id;


--
-- Name: order_transports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_transports (
    id integer NOT NULL,
    scheduled_at timestamp with time zone,
    timeslot character varying,
    transport_type character varying,
    contact_id integer,
    gogovan_order_id integer,
    order_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    need_english boolean DEFAULT false,
    need_cart boolean DEFAULT false,
    need_carry boolean DEFAULT false,
    need_over_6ft boolean DEFAULT false,
    gogovan_transport_id integer,
    remove_net character varying,
    booking_type_id integer
);


--
-- Name: order_transports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_transports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_transports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.order_transports_id_seq OWNED BY public.order_transports.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    status character varying,
    code character varying,
    detail_type character varying,
    detail_id integer,
    stockit_contact_id integer,
    stockit_organisation_id integer,
    stockit_id integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone NOT NULL,
    description text,
    stockit_activity_id integer,
    country_id integer,
    created_by_id integer,
    processed_by_id integer,
    organisation_id integer,
    state character varying,
    purpose_description text,
    processed_at timestamp with time zone,
    process_completed_by_id integer,
    process_completed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancelled_by_id integer,
    closed_at timestamp with time zone,
    closed_by_id integer,
    dispatch_started_at timestamp with time zone,
    dispatch_started_by_id integer,
    submitted_by_id integer,
    submitted_at timestamp with time zone,
    people_helped integer DEFAULT 0,
    beneficiary_id integer,
    address_id integer,
    district_id integer
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: orders_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders_packages (
    id integer NOT NULL,
    package_id integer,
    order_id integer,
    state character varying,
    quantity integer,
    updated_by_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    sent_on timestamp with time zone
);


--
-- Name: orders_packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_packages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_packages_id_seq OWNED BY public.orders_packages.id;


--
-- Name: orders_purposes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders_purposes (
    id integer NOT NULL,
    order_id integer,
    purpose_id integer
);


--
-- Name: orders_purposes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_purposes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_purposes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_purposes_id_seq OWNED BY public.orders_purposes.id;


--
-- Name: organisation_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organisation_types (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    category_en character varying,
    category_zh_tw character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: organisation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organisation_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organisation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organisation_types_id_seq OWNED BY public.organisation_types.id;


--
-- Name: organisations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organisations (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    organisation_type_id integer,
    description_en text,
    description_zh_tw text,
    registration character varying,
    website character varying,
    country_id integer,
    district_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    gih3_id character varying
);


--
-- Name: organisations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organisations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organisations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organisations_id_seq OWNED BY public.organisations.id;


--
-- Name: organisations_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organisations_users (
    id integer NOT NULL,
    organisation_id integer,
    user_id integer,
    "position" character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: organisations_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organisations_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organisations_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organisations_users_id_seq OWNED BY public.organisations_users.id;


--
-- Name: package_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.package_categories (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    parent_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: package_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.package_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: package_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.package_categories_id_seq OWNED BY public.package_categories.id;


--
-- Name: package_categories_package_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.package_categories_package_types (
    id integer NOT NULL,
    package_type_id integer,
    package_category_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: package_categories_package_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.package_categories_package_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: package_categories_package_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.package_categories_package_types_id_seq OWNED BY public.package_categories_package_types.id;


--
-- Name: package_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.package_types (
    id integer NOT NULL,
    code character varying,
    name_en character varying,
    name_zh_tw character varying,
    other_terms_en character varying,
    other_terms_zh_tw character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    visible_in_selects boolean DEFAULT false,
    stockit_id integer,
    location_id integer
);


--
-- Name: package_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.package_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: package_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.package_types_id_seq OWNED BY public.package_types.id;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packages (
    id integer NOT NULL,
    quantity integer,
    length integer,
    width integer,
    height integer,
    notes text,
    item_id integer,
    state character varying,
    received_at timestamp with time zone,
    rejected_at timestamp with time zone,
    package_type_id integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    offer_id integer DEFAULT 0,
    inventory_number character varying,
    location_id integer,
    designation_name character varying,
    donor_condition_id integer,
    grade character varying,
    box_id integer,
    pallet_id integer,
    stockit_id integer,
    order_id integer,
    stockit_sent_on date,
    stockit_designated_on date,
    stockit_designated_by_id integer,
    stockit_sent_by_id integer,
    favourite_image_id integer,
    stockit_moved_on date,
    stockit_moved_by_id integer,
    saleable boolean DEFAULT false,
    set_item_id integer,
    case_number character varying,
    allow_web_publish boolean,
    received_quantity integer
);


--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.packages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.packages_id_seq OWNED BY public.packages.id;


--
-- Name: packages_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packages_locations (
    id integer NOT NULL,
    package_id integer,
    location_id integer,
    quantity integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    reference_to_orders_package integer
);


--
-- Name: packages_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.packages_locations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packages_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.packages_locations_id_seq OWNED BY public.packages_locations.id;


--
-- Name: pallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pallets (
    id integer NOT NULL,
    pallet_number character varying,
    description character varying,
    comments text,
    stockit_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: pallets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pallets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pallets_id_seq OWNED BY public.pallets.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id integer NOT NULL,
    name character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: purposes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purposes (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: purposes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purposes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purposes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purposes_id_seq OWNED BY public.purposes.id;


--
-- Name: rejection_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rejection_reasons (
    id integer NOT NULL,
    name_en character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_zh_tw character varying
);


--
-- Name: rejection_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rejection_reasons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rejection_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rejection_reasons_id_seq OWNED BY public.rejection_reasons.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    id integer NOT NULL,
    role_id integer,
    permission_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.role_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.role_permissions_id_seq OWNED BY public.role_permissions.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schedules (
    id integer NOT NULL,
    resource character varying,
    slot integer,
    slot_name character varying,
    zone character varying,
    scheduled_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schedules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schedules_id_seq OWNED BY public.schedules.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: stockit_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stockit_activities (
    id integer NOT NULL,
    name character varying,
    stockit_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: stockit_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stockit_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stockit_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stockit_activities_id_seq OWNED BY public.stockit_activities.id;


--
-- Name: stockit_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stockit_contacts (
    id integer NOT NULL,
    first_name character varying,
    last_name character varying,
    mobile_phone_number character varying,
    phone_number character varying,
    stockit_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: stockit_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stockit_contacts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stockit_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stockit_contacts_id_seq OWNED BY public.stockit_contacts.id;


--
-- Name: stockit_local_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stockit_local_orders (
    id integer NOT NULL,
    client_name character varying,
    hkid_number character varying,
    reference_number character varying,
    stockit_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    purpose_of_goods text
);


--
-- Name: stockit_local_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stockit_local_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stockit_local_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stockit_local_orders_id_seq OWNED BY public.stockit_local_orders.id;


--
-- Name: stockit_organisations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stockit_organisations (
    id integer NOT NULL,
    name character varying,
    stockit_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: stockit_organisations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stockit_organisations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stockit_organisations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stockit_organisations_id_seq OWNED BY public.stockit_organisations.id;


--
-- Name: subpackage_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subpackage_types (
    id integer NOT NULL,
    package_type_id integer,
    subpackage_type_id integer,
    is_default boolean DEFAULT false,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: subpackage_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subpackage_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subpackage_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subpackage_types_id_seq OWNED BY public.subpackage_types.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    offer_id integer,
    user_id integer,
    message_id integer,
    state character varying,
    sms_reminder_sent_at timestamp with time zone
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: territories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.territories (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: territories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.territories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: territories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.territories_id_seq OWNED BY public.territories.id;


--
-- Name: timeslots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timeslots (
    id integer NOT NULL,
    name_en character varying,
    name_zh_tw character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: timeslots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.timeslots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: timeslots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.timeslots_id_seq OWNED BY public.timeslots.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id integer,
    role_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    first_name character varying,
    last_name character varying,
    mobile character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    permission_id integer,
    image_id integer,
    last_connected timestamp with time zone,
    last_disconnected timestamp with time zone,
    disabled boolean DEFAULT false,
    email character varying,
    title character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
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
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object json,
    object_changes json,
    related_id integer,
    related_type character varying,
    created_at timestamp with time zone
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- Name: appointment_slot_presets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_slot_presets ALTER COLUMN id SET DEFAULT nextval('public.appointment_slot_presets_id_seq'::regclass);


--
-- Name: appointment_slots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_slots ALTER COLUMN id SET DEFAULT nextval('public.appointment_slots_id_seq'::regclass);


--
-- Name: auth_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens ALTER COLUMN id SET DEFAULT nextval('public.auth_tokens_id_seq'::regclass);


--
-- Name: beneficiaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiaries ALTER COLUMN id SET DEFAULT nextval('public.beneficiaries_id_seq'::regclass);


--
-- Name: booking_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_types ALTER COLUMN id SET DEFAULT nextval('public.booking_types_id_seq'::regclass);


--
-- Name: boxes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes ALTER COLUMN id SET DEFAULT nextval('public.boxes_id_seq'::regclass);


--
-- Name: braintree_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.braintree_transactions ALTER COLUMN id SET DEFAULT nextval('public.braintree_transactions_id_seq'::regclass);


--
-- Name: cancellation_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellation_reasons ALTER COLUMN id SET DEFAULT nextval('public.cancellation_reasons_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: countries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries ALTER COLUMN id SET DEFAULT nextval('public.countries_id_seq'::regclass);


--
-- Name: crossroads_transports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crossroads_transports ALTER COLUMN id SET DEFAULT nextval('public.crossroads_transports_id_seq'::regclass);


--
-- Name: deliveries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deliveries ALTER COLUMN id SET DEFAULT nextval('public.deliveries_id_seq'::regclass);


--
-- Name: districts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- Name: donor_conditions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donor_conditions ALTER COLUMN id SET DEFAULT nextval('public.donor_conditions_id_seq'::regclass);


--
-- Name: gogovan_orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gogovan_orders ALTER COLUMN id SET DEFAULT nextval('public.gogovan_orders_id_seq'::regclass);


--
-- Name: gogovan_transports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gogovan_transports ALTER COLUMN id SET DEFAULT nextval('public.gogovan_transports_id_seq'::regclass);


--
-- Name: goodcity_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goodcity_requests ALTER COLUMN id SET DEFAULT nextval('public.goodcity_requests_id_seq'::regclass);


--
-- Name: holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays ALTER COLUMN id SET DEFAULT nextval('public.holidays_id_seq'::regclass);


--
-- Name: identity_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identity_types ALTER COLUMN id SET DEFAULT nextval('public.identity_types_id_seq'::regclass);


--
-- Name: images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images ALTER COLUMN id SET DEFAULT nextval('public.images_id_seq'::regclass);


--
-- Name: inventory_numbers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_numbers ALTER COLUMN id SET DEFAULT nextval('public.inventory_numbers_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: offers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offers ALTER COLUMN id SET DEFAULT nextval('public.offers_id_seq'::regclass);


--
-- Name: order_transports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_transports ALTER COLUMN id SET DEFAULT nextval('public.order_transports_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: orders_packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_packages ALTER COLUMN id SET DEFAULT nextval('public.orders_packages_id_seq'::regclass);


--
-- Name: orders_purposes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_purposes ALTER COLUMN id SET DEFAULT nextval('public.orders_purposes_id_seq'::regclass);


--
-- Name: organisation_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisation_types ALTER COLUMN id SET DEFAULT nextval('public.organisation_types_id_seq'::regclass);


--
-- Name: organisations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations ALTER COLUMN id SET DEFAULT nextval('public.organisations_id_seq'::regclass);


--
-- Name: organisations_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations_users ALTER COLUMN id SET DEFAULT nextval('public.organisations_users_id_seq'::regclass);


--
-- Name: package_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_categories ALTER COLUMN id SET DEFAULT nextval('public.package_categories_id_seq'::regclass);


--
-- Name: package_categories_package_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_categories_package_types ALTER COLUMN id SET DEFAULT nextval('public.package_categories_package_types_id_seq'::regclass);


--
-- Name: package_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_types ALTER COLUMN id SET DEFAULT nextval('public.package_types_id_seq'::regclass);


--
-- Name: packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages ALTER COLUMN id SET DEFAULT nextval('public.packages_id_seq'::regclass);


--
-- Name: packages_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages_locations ALTER COLUMN id SET DEFAULT nextval('public.packages_locations_id_seq'::regclass);


--
-- Name: pallets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pallets ALTER COLUMN id SET DEFAULT nextval('public.pallets_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: purposes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purposes ALTER COLUMN id SET DEFAULT nextval('public.purposes_id_seq'::regclass);


--
-- Name: rejection_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejection_reasons ALTER COLUMN id SET DEFAULT nextval('public.rejection_reasons_id_seq'::regclass);


--
-- Name: role_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN id SET DEFAULT nextval('public.role_permissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: schedules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedules ALTER COLUMN id SET DEFAULT nextval('public.schedules_id_seq'::regclass);


--
-- Name: stockit_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stockit_activities ALTER COLUMN id SET DEFAULT nextval('public.stockit_activities_id_seq'::regclass);


--
-- Name: stockit_contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stockit_contacts ALTER COLUMN id SET DEFAULT nextval('public.stockit_contacts_id_seq'::regclass);


--
-- Name: stockit_local_orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stockit_local_orders ALTER COLUMN id SET DEFAULT nextval('public.stockit_local_orders_id_seq'::regclass);


--
-- Name: stockit_organisations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stockit_organisations ALTER COLUMN id SET DEFAULT nextval('public.stockit_organisations_id_seq'::regclass);


--
-- Name: subpackage_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subpackage_types ALTER COLUMN id SET DEFAULT nextval('public.subpackage_types_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: territories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territories ALTER COLUMN id SET DEFAULT nextval('public.territories_id_seq'::regclass);


--
-- Name: timeslots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timeslots ALTER COLUMN id SET DEFAULT nextval('public.timeslots_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: appointment_slot_presets appointment_slot_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_slot_presets
    ADD CONSTRAINT appointment_slot_presets_pkey PRIMARY KEY (id);


--
-- Name: appointment_slots appointment_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_slots
    ADD CONSTRAINT appointment_slots_pkey PRIMARY KEY (id);


--
-- Name: auth_tokens auth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens
    ADD CONSTRAINT auth_tokens_pkey PRIMARY KEY (id);


--
-- Name: beneficiaries beneficiaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiaries
    ADD CONSTRAINT beneficiaries_pkey PRIMARY KEY (id);


--
-- Name: booking_types booking_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_types
    ADD CONSTRAINT booking_types_pkey PRIMARY KEY (id);


--
-- Name: boxes boxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes
    ADD CONSTRAINT boxes_pkey PRIMARY KEY (id);


--
-- Name: braintree_transactions braintree_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.braintree_transactions
    ADD CONSTRAINT braintree_transactions_pkey PRIMARY KEY (id);


--
-- Name: cancellation_reasons cancellation_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellation_reasons
    ADD CONSTRAINT cancellation_reasons_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: crossroads_transports crossroads_transports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crossroads_transports
    ADD CONSTRAINT crossroads_transports_pkey PRIMARY KEY (id);


--
-- Name: deliveries deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deliveries
    ADD CONSTRAINT deliveries_pkey PRIMARY KEY (id);


--
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: donor_conditions donor_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donor_conditions
    ADD CONSTRAINT donor_conditions_pkey PRIMARY KEY (id);


--
-- Name: gogovan_orders gogovan_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gogovan_orders
    ADD CONSTRAINT gogovan_orders_pkey PRIMARY KEY (id);


--
-- Name: gogovan_transports gogovan_transports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gogovan_transports
    ADD CONSTRAINT gogovan_transports_pkey PRIMARY KEY (id);


--
-- Name: goodcity_requests goodcity_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goodcity_requests
    ADD CONSTRAINT goodcity_requests_pkey PRIMARY KEY (id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: identity_types identity_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identity_types
    ADD CONSTRAINT identity_types_pkey PRIMARY KEY (id);


--
-- Name: images images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: inventory_numbers inventory_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_numbers
    ADD CONSTRAINT inventory_numbers_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: offers offers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offers
    ADD CONSTRAINT offers_pkey PRIMARY KEY (id);


--
-- Name: order_transports order_transports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_transports
    ADD CONSTRAINT order_transports_pkey PRIMARY KEY (id);


--
-- Name: orders_packages orders_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_packages
    ADD CONSTRAINT orders_packages_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: orders_purposes orders_purposes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_purposes
    ADD CONSTRAINT orders_purposes_pkey PRIMARY KEY (id);


--
-- Name: organisation_types organisation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisation_types
    ADD CONSTRAINT organisation_types_pkey PRIMARY KEY (id);


--
-- Name: organisations organisations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT organisations_pkey PRIMARY KEY (id);


--
-- Name: organisations_users organisations_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations_users
    ADD CONSTRAINT organisations_users_pkey PRIMARY KEY (id);


--
-- Name: package_categories_package_types package_categories_package_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_categories_package_types
    ADD CONSTRAINT package_categories_package_types_pkey PRIMARY KEY (id);


--
-- Name: package_categories package_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_categories
    ADD CONSTRAINT package_categories_pkey PRIMARY KEY (id);


--
-- Name: package_types package_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_types
    ADD CONSTRAINT package_types_pkey PRIMARY KEY (id);


--
-- Name: packages_locations packages_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages_locations
    ADD CONSTRAINT packages_locations_pkey PRIMARY KEY (id);


--
-- Name: packages packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: pallets pallets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pallets
    ADD CONSTRAINT pallets_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: purposes purposes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purposes
    ADD CONSTRAINT purposes_pkey PRIMARY KEY (id);


--
-- Name: rejection_reasons rejection_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejection_reasons
    ADD CONSTRAINT rejection_reasons_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schedules schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_pkey PRIMARY KEY (id);


--
-- Name: stockit_activities stockit_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stockit_activities
    ADD CONSTRAINT stockit_activities_pkey PRIMARY KEY (id);


--
-- Name: stockit_contacts stockit_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stockit_contacts
    ADD CONSTRAINT stockit_contacts_pkey PRIMARY KEY (id);


--
-- Name: stockit_local_orders stockit_local_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stockit_local_orders
    ADD CONSTRAINT stockit_local_orders_pkey PRIMARY KEY (id);


--
-- Name: stockit_organisations stockit_organisations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stockit_organisations
    ADD CONSTRAINT stockit_organisations_pkey PRIMARY KEY (id);


--
-- Name: subpackage_types subpackage_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subpackage_types
    ADD CONSTRAINT subpackage_types_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: territories territories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territories
    ADD CONSTRAINT territories_pkey PRIMARY KEY (id);


--
-- Name: timeslots timeslots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timeslots
    ADD CONSTRAINT timeslots_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: index_addresses_on_addressable_id_and_addressable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_addressable_id_and_addressable_type ON public.addresses USING btree (addressable_id, addressable_type);


--
-- Name: index_addresses_on_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_district_id ON public.addresses USING btree (district_id);


--
-- Name: index_auth_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auth_tokens_on_user_id ON public.auth_tokens USING btree (user_id);


--
-- Name: index_beneficiaries_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_beneficiaries_on_created_by_id ON public.beneficiaries USING btree (created_by_id);


--
-- Name: index_beneficiaries_on_identity_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_beneficiaries_on_identity_type_id ON public.beneficiaries USING btree (identity_type_id);


--
-- Name: index_boxes_on_pallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_boxes_on_pallet_id ON public.boxes USING btree (pallet_id);


--
-- Name: index_braintree_transactions_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_braintree_transactions_on_customer_id ON public.braintree_transactions USING btree (customer_id);


--
-- Name: index_deliveries_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_contact_id ON public.deliveries USING btree (contact_id);


--
-- Name: index_deliveries_on_gogovan_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_gogovan_order_id ON public.deliveries USING btree (gogovan_order_id);


--
-- Name: index_deliveries_on_offer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_offer_id ON public.deliveries USING btree (offer_id);


--
-- Name: index_deliveries_on_schedule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_schedule_id ON public.deliveries USING btree (schedule_id);


--
-- Name: index_districts_on_territory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_territory_id ON public.districts USING btree (territory_id);


--
-- Name: index_gogovan_orders_on_ggv_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_gogovan_orders_on_ggv_uuid ON public.gogovan_orders USING btree (ggv_uuid);


--
-- Name: index_goodcity_requests_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_goodcity_requests_on_created_by_id ON public.goodcity_requests USING btree (created_by_id);


--
-- Name: index_goodcity_requests_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_goodcity_requests_on_order_id ON public.goodcity_requests USING btree (order_id);


--
-- Name: index_goodcity_requests_on_package_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_goodcity_requests_on_package_type_id ON public.goodcity_requests USING btree (package_type_id);


--
-- Name: index_images_on_imageable_id_and_imageable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_images_on_imageable_id_and_imageable_type ON public.images USING btree (imageable_id, imageable_type);


--
-- Name: index_items_on_donor_condition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_donor_condition_id ON public.items USING btree (donor_condition_id);


--
-- Name: index_items_on_offer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_offer_id ON public.items USING btree (offer_id);


--
-- Name: index_items_on_package_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_package_type_id ON public.items USING btree (package_type_id);


--
-- Name: index_items_on_rejection_reason_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_rejection_reason_id ON public.items USING btree (rejection_reason_id);


--
-- Name: index_messages_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_item_id ON public.messages USING btree (item_id);


--
-- Name: index_messages_on_offer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_offer_id ON public.messages USING btree (offer_id);


--
-- Name: index_messages_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_sender_id ON public.messages USING btree (sender_id);


--
-- Name: index_offers_on_cancellation_reason_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offers_on_cancellation_reason_id ON public.offers USING btree (cancellation_reason_id);


--
-- Name: index_offers_on_closed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offers_on_closed_by_id ON public.offers USING btree (closed_by_id);


--
-- Name: index_offers_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offers_on_created_by_id ON public.offers USING btree (created_by_id);


--
-- Name: index_offers_on_crossroads_transport_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offers_on_crossroads_transport_id ON public.offers USING btree (crossroads_transport_id);


--
-- Name: index_offers_on_gogovan_transport_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offers_on_gogovan_transport_id ON public.offers USING btree (gogovan_transport_id);


--
-- Name: index_offers_on_received_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offers_on_received_by_id ON public.offers USING btree (received_by_id);


--
-- Name: index_offers_on_reviewed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offers_on_reviewed_by_id ON public.offers USING btree (reviewed_by_id);


--
-- Name: index_order_transports_on_booking_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_transports_on_booking_type_id ON public.order_transports USING btree (booking_type_id);


--
-- Name: index_order_transports_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_transports_on_contact_id ON public.order_transports USING btree (contact_id);


--
-- Name: index_order_transports_on_gogovan_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_transports_on_gogovan_order_id ON public.order_transports USING btree (gogovan_order_id);


--
-- Name: index_order_transports_on_gogovan_transport_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_transports_on_gogovan_transport_id ON public.order_transports USING btree (gogovan_transport_id);


--
-- Name: index_order_transports_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_transports_on_order_id ON public.order_transports USING btree (order_id);


--
-- Name: index_orders_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_address_id ON public.orders USING btree (address_id);


--
-- Name: index_orders_on_beneficiary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_beneficiary_id ON public.orders USING btree (beneficiary_id);


--
-- Name: index_orders_on_cancelled_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_cancelled_by_id ON public.orders USING btree (cancelled_by_id);


--
-- Name: index_orders_on_closed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_closed_by_id ON public.orders USING btree (closed_by_id);


--
-- Name: index_orders_on_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_country_id ON public.orders USING btree (country_id);


--
-- Name: index_orders_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_created_by_id ON public.orders USING btree (created_by_id);


--
-- Name: index_orders_on_detail_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_detail_id ON public.orders USING btree (detail_id);


--
-- Name: index_orders_on_detail_id_and_detail_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_detail_id_and_detail_type ON public.orders USING btree (detail_id, detail_type);


--
-- Name: index_orders_on_dispatch_started_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_dispatch_started_by_id ON public.orders USING btree (dispatch_started_by_id);


--
-- Name: index_orders_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_organisation_id ON public.orders USING btree (organisation_id);


--
-- Name: index_orders_on_process_completed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_process_completed_by_id ON public.orders USING btree (process_completed_by_id);


--
-- Name: index_orders_on_processed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_processed_by_id ON public.orders USING btree (processed_by_id);


--
-- Name: index_orders_on_stockit_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_stockit_activity_id ON public.orders USING btree (stockit_activity_id);


--
-- Name: index_orders_on_stockit_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_stockit_contact_id ON public.orders USING btree (stockit_contact_id);


--
-- Name: index_orders_on_stockit_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_stockit_organisation_id ON public.orders USING btree (stockit_organisation_id);


--
-- Name: index_orders_on_submitted_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_submitted_by_id ON public.orders USING btree (submitted_by_id);


--
-- Name: index_orders_packages_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_packages_on_order_id ON public.orders_packages USING btree (order_id);


--
-- Name: index_orders_packages_on_order_id_and_package_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_packages_on_order_id_and_package_id ON public.orders_packages USING btree (order_id, package_id);


--
-- Name: index_orders_packages_on_package_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_packages_on_package_id ON public.orders_packages USING btree (package_id);


--
-- Name: index_orders_packages_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_packages_on_updated_by_id ON public.orders_packages USING btree (updated_by_id);


--
-- Name: index_orders_purposes_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_purposes_on_order_id ON public.orders_purposes USING btree (order_id);


--
-- Name: index_orders_purposes_on_purpose_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_purposes_on_purpose_id ON public.orders_purposes USING btree (purpose_id);


--
-- Name: index_organisations_on_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_on_country_id ON public.organisations USING btree (country_id);


--
-- Name: index_organisations_on_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_on_district_id ON public.organisations USING btree (district_id);


--
-- Name: index_organisations_on_organisation_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_on_organisation_type_id ON public.organisations USING btree (organisation_type_id);


--
-- Name: index_organisations_users_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_users_on_organisation_id ON public.organisations_users USING btree (organisation_id);


--
-- Name: index_organisations_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_users_on_user_id ON public.organisations_users USING btree (user_id);


--
-- Name: index_package_categories_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_package_categories_on_parent_id ON public.package_categories USING btree (parent_id);


--
-- Name: index_package_categories_package_types_on_package_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_package_categories_package_types_on_package_category_id ON public.package_categories_package_types USING btree (package_category_id);


--
-- Name: index_package_categories_package_types_on_package_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_package_categories_package_types_on_package_type_id ON public.package_categories_package_types USING btree (package_type_id);


--
-- Name: index_package_types_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_package_types_on_location_id ON public.package_types USING btree (location_id);


--
-- Name: index_packages_locations_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_locations_on_location_id ON public.packages_locations USING btree (location_id);


--
-- Name: index_packages_locations_on_location_id_and_package_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_locations_on_location_id_and_package_id ON public.packages_locations USING btree (location_id, package_id);


--
-- Name: index_packages_locations_on_package_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_locations_on_package_id ON public.packages_locations USING btree (package_id);


--
-- Name: index_packages_on_box_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_box_id ON public.packages USING btree (box_id);


--
-- Name: index_packages_on_donor_condition_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_donor_condition_id ON public.packages USING btree (donor_condition_id);


--
-- Name: index_packages_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_item_id ON public.packages USING btree (item_id);


--
-- Name: index_packages_on_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_location_id ON public.packages USING btree (location_id);


--
-- Name: index_packages_on_offer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_offer_id ON public.packages USING btree (offer_id);


--
-- Name: index_packages_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_order_id ON public.packages USING btree (order_id);


--
-- Name: index_packages_on_package_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_package_type_id ON public.packages USING btree (package_type_id);


--
-- Name: index_packages_on_pallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_pallet_id ON public.packages USING btree (pallet_id);


--
-- Name: index_packages_on_set_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_set_item_id ON public.packages USING btree (set_item_id);


--
-- Name: index_packages_on_stockit_designated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_stockit_designated_by_id ON public.packages USING btree (stockit_designated_by_id);


--
-- Name: index_packages_on_stockit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_stockit_id ON public.packages USING btree (stockit_id);


--
-- Name: index_packages_on_stockit_moved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_stockit_moved_by_id ON public.packages USING btree (stockit_moved_by_id);


--
-- Name: index_packages_on_stockit_sent_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_stockit_sent_by_id ON public.packages USING btree (stockit_sent_by_id);


--
-- Name: index_role_permissions_on_permission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_permissions_on_permission_id ON public.role_permissions USING btree (permission_id);


--
-- Name: index_role_permissions_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_permissions_on_role_id ON public.role_permissions USING btree (role_id);


--
-- Name: index_subpackage_types_on_package_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subpackage_types_on_package_type_id ON public.subpackage_types USING btree (package_type_id);


--
-- Name: index_subpackage_types_on_package_type_id_and_package_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subpackage_types_on_package_type_id_and_package_type_id ON public.subpackage_types USING btree (package_type_id, package_type_id);


--
-- Name: index_subpackage_types_on_subpackage_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subpackage_types_on_subpackage_type_id ON public.subpackage_types USING btree (subpackage_type_id);


--
-- Name: index_user_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_role_id ON public.user_roles USING btree (role_id);


--
-- Name: index_user_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_user_id ON public.user_roles USING btree (user_id);


--
-- Name: index_users_on_image_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_image_id ON public.users USING btree (image_id);


--
-- Name: index_users_on_mobile; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_mobile ON public.users USING btree (mobile);


--
-- Name: index_users_on_permission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_permission_id ON public.users USING btree (permission_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_related_id_and_related_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_related_id_and_related_type ON public.versions USING btree (related_id, related_type);


--
-- Name: index_versions_on_whodunnit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_whodunnit ON public.versions USING btree (whodunnit);


--
-- Name: inventory_numbers_search_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_numbers_search_idx ON public.packages USING gin (inventory_number public.gin_trgm_ops);


--
-- Name: offer_user_message; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX offer_user_message ON public.subscriptions USING btree (offer_id, user_id, message_id);


--
-- Name: orders_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_code_idx ON public.orders USING gin (code public.gin_trgm_ops);


--
-- Name: st_contacts_first_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX st_contacts_first_name_idx ON public.stockit_contacts USING gin (first_name public.gin_trgm_ops);


--
-- Name: st_contacts_last_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX st_contacts_last_name_idx ON public.stockit_contacts USING gin (last_name public.gin_trgm_ops);


--
-- Name: st_contacts_mobile_phone_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX st_contacts_mobile_phone_number_idx ON public.stockit_contacts USING gin (mobile_phone_number public.gin_trgm_ops);


--
-- Name: st_contacts_phone_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX st_contacts_phone_number_idx ON public.stockit_contacts USING gin (phone_number public.gin_trgm_ops);


--
-- Name: st_local_orders_client_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX st_local_orders_client_name_idx ON public.stockit_local_orders USING gin (client_name public.gin_trgm_ops);


--
-- Name: st_organisations_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX st_organisations_name_idx ON public.stockit_organisations USING gin (name public.gin_trgm_ops);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: beneficiaries fk_rails_2c1fc874b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiaries
    ADD CONSTRAINT fk_rails_2c1fc874b0 FOREIGN KEY (identity_type_id) REFERENCES public.identity_types(id);


--
-- Name: goodcity_requests fk_rails_3015d19682; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goodcity_requests
    ADD CONSTRAINT fk_rails_3015d19682 FOREIGN KEY (package_type_id) REFERENCES public.package_types(id);


--
-- Name: organisations_users fk_rails_3fb2fe50fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations_users
    ADD CONSTRAINT fk_rails_3fb2fe50fb FOREIGN KEY (organisation_id) REFERENCES public.organisations(id);


--
-- Name: organisations fk_rails_574ca3be5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT fk_rails_574ca3be5d FOREIGN KEY (district_id) REFERENCES public.districts(id);


--
-- Name: organisations fk_rails_69adf6173e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT fk_rails_69adf6173e FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: organisations fk_rails_7b7111c3a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT fk_rails_7b7111c3a1 FOREIGN KEY (organisation_type_id) REFERENCES public.organisation_types(id);


--
-- Name: goodcity_requests fk_rails_b30d4199d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goodcity_requests
    ADD CONSTRAINT fk_rails_b30d4199d6 FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: organisations_users fk_rails_fee009160b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations_users
    ADD CONSTRAINT fk_rails_fee009160b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20140625090842');

INSERT INTO schema_migrations (version) VALUES ('20140625091346');

INSERT INTO schema_migrations (version) VALUES ('20140626091541');

INSERT INTO schema_migrations (version) VALUES ('20140627024957');

INSERT INTO schema_migrations (version) VALUES ('20140627032450');

INSERT INTO schema_migrations (version) VALUES ('20140627033149');

INSERT INTO schema_migrations (version) VALUES ('20140627063519');

INSERT INTO schema_migrations (version) VALUES ('20140627070011');

INSERT INTO schema_migrations (version) VALUES ('20140627072216');

INSERT INTO schema_migrations (version) VALUES ('20140628072714');

INSERT INTO schema_migrations (version) VALUES ('20140710181544');

INSERT INTO schema_migrations (version) VALUES ('20140717103134');

INSERT INTO schema_migrations (version) VALUES ('20140723113838');

INSERT INTO schema_migrations (version) VALUES ('20140724091537');

INSERT INTO schema_migrations (version) VALUES ('20140724092941');

INSERT INTO schema_migrations (version) VALUES ('20140725080520');

INSERT INTO schema_migrations (version) VALUES ('20140801033500');

INSERT INTO schema_migrations (version) VALUES ('20140801094658');

INSERT INTO schema_migrations (version) VALUES ('20140812160148');

INSERT INTO schema_migrations (version) VALUES ('20140816101803');

INSERT INTO schema_migrations (version) VALUES ('20140827070434');

INSERT INTO schema_migrations (version) VALUES ('20140827085942');

INSERT INTO schema_migrations (version) VALUES ('20140830084303');

INSERT INTO schema_migrations (version) VALUES ('20140901070003');

INSERT INTO schema_migrations (version) VALUES ('20140903062513');

INSERT INTO schema_migrations (version) VALUES ('20140905075736');

INSERT INTO schema_migrations (version) VALUES ('20140907173523');

INSERT INTO schema_migrations (version) VALUES ('20140912042854');

INSERT INTO schema_migrations (version) VALUES ('20140916093546');

INSERT INTO schema_migrations (version) VALUES ('20140917102054');

INSERT INTO schema_migrations (version) VALUES ('20140918093921');

INSERT INTO schema_migrations (version) VALUES ('20140919034111');

INSERT INTO schema_migrations (version) VALUES ('20140920030756');

INSERT INTO schema_migrations (version) VALUES ('20140920041523');

INSERT INTO schema_migrations (version) VALUES ('20141009081013');

INSERT INTO schema_migrations (version) VALUES ('20141010044118');

INSERT INTO schema_migrations (version) VALUES ('20141015063630');

INSERT INTO schema_migrations (version) VALUES ('20141030065028');

INSERT INTO schema_migrations (version) VALUES ('20141106114218');

INSERT INTO schema_migrations (version) VALUES ('20141119092907');

INSERT INTO schema_migrations (version) VALUES ('20141121115105');

INSERT INTO schema_migrations (version) VALUES ('20141121115630');

INSERT INTO schema_migrations (version) VALUES ('20141127143205');

INSERT INTO schema_migrations (version) VALUES ('20141127181633');

INSERT INTO schema_migrations (version) VALUES ('20141128085941');

INSERT INTO schema_migrations (version) VALUES ('20141203070037');

INSERT INTO schema_migrations (version) VALUES ('20141204025155');

INSERT INTO schema_migrations (version) VALUES ('20141212100406');

INSERT INTO schema_migrations (version) VALUES ('20141217065814');

INSERT INTO schema_migrations (version) VALUES ('20141220071401');

INSERT INTO schema_migrations (version) VALUES ('20141221110116');

INSERT INTO schema_migrations (version) VALUES ('20141223055447');

INSERT INTO schema_migrations (version) VALUES ('20141223055519');

INSERT INTO schema_migrations (version) VALUES ('20141230081658');

INSERT INTO schema_migrations (version) VALUES ('20150123125149');

INSERT INTO schema_migrations (version) VALUES ('20150128113512');

INSERT INTO schema_migrations (version) VALUES ('20150321152144');

INSERT INTO schema_migrations (version) VALUES ('20150328034808');

INSERT INTO schema_migrations (version) VALUES ('20150331053636');

INSERT INTO schema_migrations (version) VALUES ('20150401030717');

INSERT INTO schema_migrations (version) VALUES ('20150417140142');

INSERT INTO schema_migrations (version) VALUES ('20150428061827');

INSERT INTO schema_migrations (version) VALUES ('20150428092154');

INSERT INTO schema_migrations (version) VALUES ('20150428135028');

INSERT INTO schema_migrations (version) VALUES ('20150505060613');

INSERT INTO schema_migrations (version) VALUES ('20150514091411');

INSERT INTO schema_migrations (version) VALUES ('20150515072541');

INSERT INTO schema_migrations (version) VALUES ('20150515075646');

INSERT INTO schema_migrations (version) VALUES ('20150518123926');

INSERT INTO schema_migrations (version) VALUES ('20150525102526');

INSERT INTO schema_migrations (version) VALUES ('20150603062610');

INSERT INTO schema_migrations (version) VALUES ('20150709152138');

INSERT INTO schema_migrations (version) VALUES ('20150710135052');

INSERT INTO schema_migrations (version) VALUES ('20150716133846');

INSERT INTO schema_migrations (version) VALUES ('20151007060024');

INSERT INTO schema_migrations (version) VALUES ('20151126083717');

INSERT INTO schema_migrations (version) VALUES ('20151221075809');

INSERT INTO schema_migrations (version) VALUES ('20160106083140');

INSERT INTO schema_migrations (version) VALUES ('20160106115801');

INSERT INTO schema_migrations (version) VALUES ('20160107151224');

INSERT INTO schema_migrations (version) VALUES ('20160114123637');

INSERT INTO schema_migrations (version) VALUES ('20160114124856');

INSERT INTO schema_migrations (version) VALUES ('20160125103238');

INSERT INTO schema_migrations (version) VALUES ('20160127065409');

INSERT INTO schema_migrations (version) VALUES ('20160202074857');

INSERT INTO schema_migrations (version) VALUES ('20160216133741');

INSERT INTO schema_migrations (version) VALUES ('20160216144430');

INSERT INTO schema_migrations (version) VALUES ('20160304065357');

INSERT INTO schema_migrations (version) VALUES ('20160307073802');

INSERT INTO schema_migrations (version) VALUES ('20160412070145');

INSERT INTO schema_migrations (version) VALUES ('20160503103214');

INSERT INTO schema_migrations (version) VALUES ('20160516080902');

INSERT INTO schema_migrations (version) VALUES ('20160516102120');

INSERT INTO schema_migrations (version) VALUES ('20160516102304');

INSERT INTO schema_migrations (version) VALUES ('20160516102425');

INSERT INTO schema_migrations (version) VALUES ('20160531083859');

INSERT INTO schema_migrations (version) VALUES ('20160607134338');

INSERT INTO schema_migrations (version) VALUES ('20160608105118');

INSERT INTO schema_migrations (version) VALUES ('20160608124736');

INSERT INTO schema_migrations (version) VALUES ('20160608142632');

INSERT INTO schema_migrations (version) VALUES ('20160609075943');

INSERT INTO schema_migrations (version) VALUES ('20160610072201');

INSERT INTO schema_migrations (version) VALUES ('20160611063247');

INSERT INTO schema_migrations (version) VALUES ('20160617144957');

INSERT INTO schema_migrations (version) VALUES ('20160630131417');

INSERT INTO schema_migrations (version) VALUES ('20160704113332');

INSERT INTO schema_migrations (version) VALUES ('20160706144644');

INSERT INTO schema_migrations (version) VALUES ('20160707064711');

INSERT INTO schema_migrations (version) VALUES ('20160708145151');

INSERT INTO schema_migrations (version) VALUES ('20160719095224');

INSERT INTO schema_migrations (version) VALUES ('20160720103535');

INSERT INTO schema_migrations (version) VALUES ('20160722111406');

INSERT INTO schema_migrations (version) VALUES ('20160725142942');

INSERT INTO schema_migrations (version) VALUES ('20160728122938');

INSERT INTO schema_migrations (version) VALUES ('20160817101116');

INSERT INTO schema_migrations (version) VALUES ('20160825062828');

INSERT INTO schema_migrations (version) VALUES ('20160826104123');

INSERT INTO schema_migrations (version) VALUES ('20160826115033');

INSERT INTO schema_migrations (version) VALUES ('20160827134441');

INSERT INTO schema_migrations (version) VALUES ('20160831054754');

INSERT INTO schema_migrations (version) VALUES ('20160916071946');

INSERT INTO schema_migrations (version) VALUES ('20160916080826');

INSERT INTO schema_migrations (version) VALUES ('20160916102800');

INSERT INTO schema_migrations (version) VALUES ('20160916113610');

INSERT INTO schema_migrations (version) VALUES ('20160916115655');

INSERT INTO schema_migrations (version) VALUES ('20160916115951');

INSERT INTO schema_migrations (version) VALUES ('20160919120241');

INSERT INTO schema_migrations (version) VALUES ('20160919134728');

INSERT INTO schema_migrations (version) VALUES ('20160920063021');

INSERT INTO schema_migrations (version) VALUES ('20160922141820');

INSERT INTO schema_migrations (version) VALUES ('20160923141615');

INSERT INTO schema_migrations (version) VALUES ('20161110142220');

INSERT INTO schema_migrations (version) VALUES ('20161207055623');

INSERT INTO schema_migrations (version) VALUES ('20161207064453');

INSERT INTO schema_migrations (version) VALUES ('20161208082219');

INSERT INTO schema_migrations (version) VALUES ('20161208115855');

INSERT INTO schema_migrations (version) VALUES ('20170119144255');

INSERT INTO schema_migrations (version) VALUES ('20170513084258');

INSERT INTO schema_migrations (version) VALUES ('20170517090414');

INSERT INTO schema_migrations (version) VALUES ('20171213140618');

INSERT INTO schema_migrations (version) VALUES ('20171218105636');

INSERT INTO schema_migrations (version) VALUES ('20180214103728');

INSERT INTO schema_migrations (version) VALUES ('20180214103753');

INSERT INTO schema_migrations (version) VALUES ('20180214104436');

INSERT INTO schema_migrations (version) VALUES ('20180528084205');

INSERT INTO schema_migrations (version) VALUES ('20180529014537');

INSERT INTO schema_migrations (version) VALUES ('20180529014554');

INSERT INTO schema_migrations (version) VALUES ('20180529015651');

INSERT INTO schema_migrations (version) VALUES ('20180529015715');

INSERT INTO schema_migrations (version) VALUES ('20180529040914');

INSERT INTO schema_migrations (version) VALUES ('20180529040927');

INSERT INTO schema_migrations (version) VALUES ('20180604024724');

INSERT INTO schema_migrations (version) VALUES ('20180604025006');

INSERT INTO schema_migrations (version) VALUES ('20180612100305');

INSERT INTO schema_migrations (version) VALUES ('20180620045905');

INSERT INTO schema_migrations (version) VALUES ('20180620045951');

INSERT INTO schema_migrations (version) VALUES ('20180713124518');

INSERT INTO schema_migrations (version) VALUES ('20180723112054');

INSERT INTO schema_migrations (version) VALUES ('20180827034143');

INSERT INTO schema_migrations (version) VALUES ('20180829050010');

INSERT INTO schema_migrations (version) VALUES ('20180924074059');

INSERT INTO schema_migrations (version) VALUES ('20180924082712');

INSERT INTO schema_migrations (version) VALUES ('20180928023953');

INSERT INTO schema_migrations (version) VALUES ('20180928031017');

INSERT INTO schema_migrations (version) VALUES ('20181003055950');

INSERT INTO schema_migrations (version) VALUES ('20181016071437');

INSERT INTO schema_migrations (version) VALUES ('20181024072154');

INSERT INTO schema_migrations (version) VALUES ('20181026072054');

INSERT INTO schema_migrations (version) VALUES ('20181106123704');

INSERT INTO schema_migrations (version) VALUES ('20181106130437');

INSERT INTO schema_migrations (version) VALUES ('20181120115456');

INSERT INTO schema_migrations (version) VALUES ('20181121040221');

INSERT INTO schema_migrations (version) VALUES ('20181121053137');

INSERT INTO schema_migrations (version) VALUES ('20181122111014');

INSERT INTO schema_migrations (version) VALUES ('20181207070950');

INSERT INTO schema_migrations (version) VALUES ('20181211124007');

