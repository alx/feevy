CREATE TABLE users (
		id serial NOT NULL primary key,
		"login" character varying(80),
		cryptpassword character varying(40),
		validkey character varying(40),
		email character varying(100) DEFAULT ''::character varying NOT NULL,
		newemail character varying(100),
		ipaddr character varying(15) DEFAULT ''::character varying NOT NULL,
		created_at timestamp without time zone DEFAULT now() NOT NULL,
		updated_at timestamp without time zone DEFAULT now() NOT NULL,
		domains text NOT NULL,
		firstname character varying(40) DEFAULT ''::character varying NOT NULL,
		lastname character varying(40) DEFAULT ''::character varying NOT NULL,
		confirmed smallint DEFAULT 0 NOT NULL,
		image bytea
		);
