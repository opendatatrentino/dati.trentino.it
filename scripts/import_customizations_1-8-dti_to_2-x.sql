-- ----------------------------------------
-- Ckan 1.8-dti -> 2.x
-- SQL migration script
-- Author: Samuele Santi
-- Date: 2013-08-22
-- ----------------------------------------

--
-- All the imported groups are actually organizations
--

UPDATE "group" SET
	is_organization = TRUE,
	name = 'org-' || name;

UPDATE "group_revision" SET
	is_organization = TRUE,
	name = 'org-' || name;


--
-- Cleanup some garbage
--

TRUNCATE TABLE celery_taskmeta cascade;
TRUNCATE TABLE celery_tasksetmeta cascade;
TRUNCATE TABLE kombu_message cascade;
TRUNCATE TABLE kombu_queue cascade;


--
-- The "categories" were stored as tags -> import them
--


-- Create a fake revision to use for our update
INSERT INTO "revision"
	(id, "timestamp", "author", "message", "state")
VALUES (
	'special-revision-import-18-dti-to-2x',
	now(),
	'admin',
	'Import from 1.8-dti to 2.x',
	'active'
);

-- Table: group
INSERT INTO "group"
SELECT
	tag.id::text as id,
	REPLACE(LOWER(tag.name::text), ' ', '-') as "name",
	tag.name::text as title,
	''::text as description,
	now()::timestamp as created,
	'active'::text as state,
	'special-revision-import-18-dti-to-2x'::text as revision_id,
	'group'::text as "type",
	'approved'::text as approval_status,
	''::text as image_url,
	FALSE::boolean as is_organization
FROM tag
WHERE vocabulary_id = (
	SELECT id FROM vocabulary
	WHERE name='category_vocab'
	);


-- Table: group_revision
INSERT INTO "group_revision"
SELECT
	tag.id::text as id,
	REPLACE(LOWER(tag.name::text), ' ', '-') as "name",
	tag.name::text as "title",
	''::text as description,
	now()::timestamp as created,
	'active'::text as state,
	'special-revision-import-18-dti-to-2x'::text as revision_id,
	tag.id::text as continuity_id,
	''::text as expired_id,
	now()::timestamp as revision_timestamp,
	'9999-12-31 00:00:00'::timestamp as expired_timestamp,
	TRUE::boolean as "current",
	'group'::text as "type",
	'approved'::text as "approval_status",
	''::text as "image_url",
	FALSE::boolean as "is_organization"
FROM tag
WHERE vocabulary_id = (
	SELECT id FROM vocabulary
	WHERE name='category_vocab'
	);

-- We need to import all package category memberships too
SELECT * FROM package_tag WHERE tag_id IN (
	SELECT id FROM tag WHERE vocabulary_id = (
		SELECT id FROM vocabulary
		WHERE "name" = 'category_vocab'
	)
);
