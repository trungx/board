UPDATE "setting_categories" SET "order" = 2 WHERE name = 'Third Party API';

UPDATE "setting_categories" SET "order" = 3 WHERE name = 'IMAP';

INSERT INTO "setting_categories" ("id", "created", "modified", "parent_id", "name", "description", "order") 
values (14, now(), now(), NULL, 'Notifications', NULL, '4');

INSERT INTO "settings" ("setting_category_id", "setting_category_parent_id", "name", "value", "description", "type", "options", "label", "order") 
VALUES
((select id from setting_categories where name = 'Notifications'), '0', 'AUTO_SUBSCRIBE_ON_BOARD', 'Enabled', '', 'select', 'Enabled,Disabled', 'Automatically subscribe a member when he''s added to a board', '1'),
((select id from setting_categories where name = 'Notifications'), '0', 'AUTO_SUBSCRIBE_ON_CARD', 'Enabled', '', 'select', 'Enabled,Disabled', 'Automatically subscribe a member when he''s added to a card', '2'), 
((select id from setting_categories where name = 'Notifications'), '0', 'DEFAULT_EMAIL_NOTIFICATION', 'Instantly', '', 'select', 'Never,Periodically,Instantly', 'Default Email Notification', '3'),
((select id from setting_categories where name = 'Notifications'), '0', 'DEFAULT_DESKTOP_NOTIFICATION', 'Enabled', '', 'select', 'Enabled,Disabled', 'Default Desktop Notification', '4'),
((select id from setting_categories where name = 'Notifications'), '0', 'IS_LIST_NOTIFICATIONS_ENABLED', 'true', '', 'checkbox', NULL, 'List level notification - when updating color, card, move, archive, unarchive, delete', '5'),
((select id from setting_categories where name = 'Notifications'), '0', 'IS_CARD_NOTIFICATIONS_ENABLED', 'true', '', 'checkbox', NULL, 'Card level notification #1 - when updating color, due date, description, move, archive, unarchive, delete', '6'),
((select id from setting_categories where name = 'Notifications'), '0', 'IS_CARD_MEMBERS_NOTIFICATIONS_ENABLED', 'true', '', 'checkbox', NULL, 'Card level notification #2 - when updating members', '7'),
((select id from setting_categories where name = 'Notifications'), '0', 'IS_CARD_LABELS_NOTIFICATIONS_ENABLED', 'true', '', 'checkbox', NULL, 'Card level notification #3 - when updating labels', '8'),
((select id from setting_categories where name = 'Notifications'), '0', 'IS_CARD_CHECKLISTS_NOTIFICATIONS_ENABLED', 'true', '', 'checkbox', NULL, 'Card level notification #4 - when updating checklist', '9'),
((select id from setting_categories where name = 'Notifications'), '0', 'IS_CARD_ATTACHMENTS_NOTIFICATIONS_ENABLED', 'true', '', 'checkbox', NULL, 'Card level notification #5 - when updating attachment', '10');

ALTER TABLE "boards" ADD "auto_subscribe_on_board" boolean NOT NULL DEFAULT 'true';

ALTER TABLE "boards" ADD "auto_subscribe_on_card" boolean NOT NULL DEFAULT 'true';

CREATE OR REPLACE VIEW boards_listing AS
SELECT board.id,
    board.name,
    to_char(board.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
    to_char(board.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
    users.username,
    users.full_name,
    users.profile_picture_path,
    users.initials,
    board.user_id,
    board.organization_id,
    board.board_visibility,
    board.background_color,
    board.background_picture_url,
    board.commenting_permissions,
    board.voting_permissions,
    (board.is_closed)::integer AS is_closed,
    (board.is_allow_organization_members_to_join)::integer AS is_allow_organization_members_to_join,
    board.boards_user_count,
    board.list_count,
    board.card_count,
    board.archived_list_count,
    board.archived_card_count,
    board.boards_subscriber_count,
    board.background_pattern_url,
    (board.is_show_image_front_of_card)::integer AS is_show_image_front_of_card,
    board.music_name,
    board.music_content,
    organizations.name AS organization_name,
    organizations.website_url AS organization_website_url,
    organizations.description AS organization_description,
    organizations.logo_url AS organization_logo_url,
    organizations.organization_visibility,
    ( SELECT array_to_json(array_agg(row_to_json(ba.*))) AS array_to_json
           FROM ( SELECT activities.id,
                    to_char(activities.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
                    to_char(activities.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
                    activities.board_id,
                    activities.list_id,
                    activities.card_id,
                    activities.user_id,
                    activities.foreign_id AS attachment_id,
                    activities.type,
                    activities.comment,
                    activities.revisions,
                    activities.root,
                    activities.freshness_ts,
                    activities.depth,
                    activities.path,
                    activities.materialized_path,
                    users_1.username,
                    users_1.role_id,
                    users_1.profile_picture_path,
                    users_1.initials
                   FROM (activities activities
                     LEFT JOIN users users_1 ON ((users_1.id = activities.user_id)))
                  WHERE (activities.board_id = board.id)
                  ORDER BY activities.freshness_ts DESC, activities.materialized_path
                 OFFSET 0
                 LIMIT 20) ba) AS activities,
    ( SELECT array_to_json(array_agg(row_to_json(bs.*))) AS array_to_json
           FROM ( SELECT boards_subscribers.id,
                    to_char(boards_subscribers.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
                    to_char(boards_subscribers.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
                    boards_subscribers.board_id,
                    boards_subscribers.user_id,
                    (boards_subscribers.is_subscribed)::integer AS is_subscribed
                   FROM board_subscribers boards_subscribers
                  WHERE (boards_subscribers.board_id = board.id)
                  ORDER BY boards_subscribers.id) bs) AS boards_subscribers,
    ( SELECT array_to_json(array_agg(row_to_json(bs.*))) AS array_to_json
           FROM ( SELECT boards_stars.id,
                    to_char(boards_stars.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
                    to_char(boards_stars.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
                    boards_stars.created,
                    boards_stars.modified,
                    boards_stars.board_id,
                    boards_stars.user_id,
                    (boards_stars.is_starred)::integer AS is_starred
                   FROM board_stars boards_stars
                  WHERE (boards_stars.board_id = board.id)
                  ORDER BY boards_stars.id) bs(id, created, modified, created_1, modified_1, board_id, user_id, is_starred)) AS boards_stars,
    ( SELECT array_to_json(array_agg(row_to_json(batt.*))) AS array_to_json
           FROM ( SELECT card_attachments.id,
                    to_char(card_attachments.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
                    to_char(card_attachments.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
                    card_attachments.card_id,
                    card_attachments.name,
                    card_attachments.path,
                    card_attachments.mimetype,
                    card_attachments.list_id,
                    card_attachments.board_id,
                    card_attachments.link
                   FROM card_attachments card_attachments
                  WHERE (card_attachments.board_id = board.id)
                  ORDER BY card_attachments.id DESC) batt) AS attachments,
    ( SELECT array_to_json(array_agg(row_to_json(bl.*))) AS array_to_json
           FROM ( SELECT lists_listing.id,
                    lists_listing.created,
                    lists_listing.modified,
                    lists_listing.board_id,
                    lists_listing.name,
                    lists_listing."position",
                    ((lists_listing.is_archived)::boolean)::integer AS is_archived,
                    lists_listing.card_count,
                    lists_listing.lists_subscriber_count,
                    lists_listing.cards,
                    lists_listing.lists_subscribers,
                    lists_listing.custom_fields,
                    lists_listing.color
                   FROM lists_listing lists_listing
                  WHERE (lists_listing.board_id = board.id)
                  ORDER BY lists_listing."position") bl) AS lists,
    ( SELECT array_to_json(array_agg(row_to_json(bu.*))) AS array_to_json
           FROM ( SELECT boards_users.id,
                    boards_users.created,
                    boards_users.modified,
                    boards_users.board_id,
                    boards_users.user_id,
                    boards_users.board_user_role_id,
                    boards_users.username,
                    boards_users.email,
                    boards_users.full_name,
                    ((boards_users.is_active)::boolean)::integer AS is_active,
                    ((boards_users.is_email_confirmed)::boolean)::integer AS is_email_confirmed,
                    boards_users.board_name,
                    boards_users.profile_picture_path,
                    boards_users.initials
                   FROM boards_users_listing boards_users
                  WHERE (boards_users.board_id = board.id)
                  ORDER BY boards_users.id) bu) AS boards_users,
    board.default_email_list_id,
    board.is_default_email_position_as_bottom,
    board.custom_fields,
    board.auto_subscribe_on_board,
    board.auto_subscribe_on_card
   FROM ((boards board
     LEFT JOIN users users ON ((users.id = board.user_id)))
     LEFT JOIN organizations organizations ON ((organizations.id = board.organization_id)));

ALTER TABLE "users" ADD "default_desktop_notification" boolean NOT NULL DEFAULT 'true';
ALTER TABLE "users" ADD "is_list_notifications_enabled" boolean NOT NULL DEFAULT 'true';
ALTER TABLE "users" ADD "is_card_notifications_enabled" boolean NOT NULL DEFAULT 'true';
ALTER TABLE "users" ADD "is_card_members_notifications_enabled" boolean NOT NULL DEFAULT 'true';
ALTER TABLE "users" ADD "is_card_labels_notifications_enabled" boolean NOT NULL DEFAULT 'true';
ALTER TABLE "users" ADD "is_card_checklists_notifications_enabled" boolean NOT NULL DEFAULT 'true';
ALTER TABLE "users" ADD "is_card_attachments_notifications_enabled" boolean NOT NULL DEFAULT 'true';

CREATE OR REPLACE VIEW users_listing AS
SELECT users.id,
    users.role_id,
    users.username,
    users.password,
    users.email,
    users.full_name,
    users.initials,
    users.about_me,
    users.profile_picture_path,
    users.notification_frequency,
    (users.is_allow_desktop_notification)::integer AS is_allow_desktop_notification,
    (users.is_active)::integer AS is_active,
    (users.is_email_confirmed)::integer AS is_email_confirmed,
    users.created_organization_count,
    users.created_board_count,
    users.joined_organization_count,
    users.list_count,
    users.joined_card_count,
    users.created_card_count,
    users.joined_board_count,
    users.checklist_count,
    users.checklist_item_completed_count,
    users.checklist_item_count,
    users.activity_count,
    users.card_voter_count,
    (users.is_productivity_beats)::integer AS is_productivity_beats,
    ( SELECT array_to_json(array_agg(row_to_json(o.*))) AS array_to_json
           FROM ( SELECT organizations_users_listing.organization_id AS id,
                    organizations_users_listing.name,
                    organizations_users_listing.description,
                    organizations_users_listing.website_url,
                    organizations_users_listing.logo_url,
                    organizations_users_listing.organization_visibility
                   FROM organizations_users_listing organizations_users_listing
                  WHERE (organizations_users_listing.user_id = users.id)
                  ORDER BY organizations_users_listing.id) o) AS organizations,
    users.last_activity_id,
    ( SELECT array_to_json(array_agg(row_to_json(o.*))) AS array_to_json
           FROM ( SELECT boards_stars.id,
                    boards_stars.board_id,
                    boards_stars.user_id,
                    (boards_stars.is_starred)::integer AS is_starred
                   FROM board_stars boards_stars
                  WHERE (boards_stars.user_id = users.id)
                  ORDER BY boards_stars.id) o) AS boards_stars,
    ( SELECT array_to_json(array_agg(row_to_json(o.*))) AS array_to_json
           FROM ( SELECT boards_users.id,
                    boards_users.board_id,
                    boards_users.user_id,
                    boards_users.board_user_role_id,
                    boards.name,
                    boards.background_picture_url,
                    boards.background_pattern_url,
                    boards.background_color
                   FROM (boards_users boards_users
                     JOIN boards ON ((boards.id = boards_users.board_id)))
                  WHERE (boards_users.user_id = users.id)
                  ORDER BY boards_users.id) o) AS boards_users,
    users.last_login_date,
    li.ip AS last_login_ip,
    lci.name AS login_city_name,
    lst.name AS login_state_name,
    lco.name AS login_country_name,
    lower((lco.iso_alpha2)::text) AS login_country_iso2,
    i.ip AS registered_ip,
    rci.name AS register_city_name,
    rst.name AS register_state_name,
    rco.name AS register_country_name,
    lower((rco.iso_alpha2)::text) AS register_country_iso2,
    lt.name AS login_type,
    to_char(users.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
    users.user_login_count,
    users.is_send_newsletter,
    users.last_email_notified_activity_id,
    users.owner_board_count,
    users.member_board_count,
    users.owner_organization_count,
    users.member_organization_count,
    users.language,
    (users.is_ldap)::integer AS is_ldap,
    users.timezone,
    users.default_desktop_notification,
    users.is_list_notifications_enabled,
    users.is_card_notifications_enabled,
    users.is_card_members_notifications_enabled,
    users.is_card_labels_notifications_enabled,
    users.is_card_checklists_notifications_enabled,
    users.is_card_attachments_notifications_enabled
   FROM (((((((((users users
     LEFT JOIN ips i ON ((i.id = users.ip_id)))
     LEFT JOIN cities rci ON ((rci.id = i.city_id)))
     LEFT JOIN states rst ON ((rst.id = i.state_id)))
     LEFT JOIN countries rco ON ((rco.id = i.country_id)))
     LEFT JOIN ips li ON ((li.id = users.last_login_ip_id)))
     LEFT JOIN cities lci ON ((lci.id = li.city_id)))
     LEFT JOIN states lst ON ((lst.id = li.state_id)))
     LEFT JOIN countries lco ON ((lco.id = li.country_id)))
     LEFT JOIN login_types lt ON ((lt.id = users.login_type_id)));

CREATE OR REPLACE VIEW activities_listing AS
SELECT activity.id,
    to_char(activity.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
    to_char(activity.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
    activity.board_id,
    activity.list_id,
    activity.card_id,
    activity.user_id,
    activity.foreign_id,
    activity.type,
    activity.comment,
    activity.revisions,
    activity.root,
    activity.freshness_ts,
    activity.depth,
    activity.path,
    activity.materialized_path,
    board.name AS board_name,
    list.name AS list_name,
    card.name AS card_name,
    users.username,
    users.full_name,
    users.profile_picture_path,
    users.initials,
    la.name AS label_name,
    card.description AS card_description,
    users.role_id AS user_role_id,
    checklist_item.name AS checklist_item_name,
    checklist.name AS checklist_item_parent_name,
    checklist1.name AS checklist_name,
    organizations.id AS organization_id,
    organizations.name AS organization_name,
    organizations.logo_url AS organization_logo_url,
    list1.name AS moved_list_name,
    to_char(activity.created, 'HH24:MI'::text) AS created_time,
    card."position" AS card_position,
    card.comment_count,
    users.default_desktop_notification,
    users.is_list_notifications_enabled,
    users.is_card_notifications_enabled,
    users.is_card_members_notifications_enabled,
    users.is_card_labels_notifications_enabled,
    users.is_card_checklists_notifications_enabled,
    users.is_card_attachments_notifications_enabled
   FROM ((((((((((activities activity
     LEFT JOIN boards board ON ((board.id = activity.board_id)))
     LEFT JOIN lists list ON ((list.id = activity.list_id)))
     LEFT JOIN lists list1 ON ((list1.id = activity.foreign_id)))
     LEFT JOIN cards card ON ((card.id = activity.card_id)))
     LEFT JOIN labels la ON (((la.id = activity.foreign_id) AND ((activity.type)::text = 'add_card_label'::text))))
     LEFT JOIN checklist_items checklist_item ON ((checklist_item.id = activity.foreign_id)))
     LEFT JOIN checklists checklist ON ((checklist.id = checklist_item.checklist_id)))
     LEFT JOIN checklists checklist1 ON ((checklist1.id = activity.foreign_id)))
     LEFT JOIN users users ON ((users.id = activity.user_id)))
     LEFT JOIN organizations organizations ON ((organizations.id = activity.organization_id)));

SELECT pg_catalog.setval('acl_organization_links_organizations_user_roles_seq', (SELECT MAX(id) FROM acl_organization_links_organizations_user_roles), true);

SELECT pg_catalog.setval('acl_board_links_boards_user_roles_seq', (SELECT MAX(id) FROM acl_board_links_boards_user_roles), true);

SELECT pg_catalog.setval('acl_links_roles_roles_id_seq', (SELECT MAX(id) FROM acl_links_roles), true);

ALTER TABLE "cards" ADD "is_due_date_notification_sent" boolean NOT NULL DEFAULT 'false';

CREATE OR REPLACE VIEW cards_listing AS
SELECT cards.id,
    to_char(cards.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
    to_char(cards.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
    cards.board_id,
    cards.list_id,
    cards.name,
    cards.description,
    to_char(cards.due_date, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS due_date,
    to_date(to_char(cards.due_date, 'YYYY/MM/DD'::text), 'YYYY/MM/DD'::text) AS to_date,
    cards."position",
    (cards.is_archived)::integer AS is_archived,
    cards.attachment_count,
    cards.checklist_count,
    cards.checklist_item_count,
    cards.checklist_item_completed_count,
    cards.label_count,
    cards.cards_user_count,
    cards.cards_subscriber_count,
    cards.card_voter_count,
    cards.activity_count,
    cards.user_id,
    cards.name AS title,
    cards.due_date AS start,
    cards.due_date AS "end",
    ( SELECT array_to_json(array_agg(row_to_json(cc.*))) AS array_to_json
           FROM ( SELECT checklists_listing.id,
                    checklists_listing.created,
                    checklists_listing.modified,
                    checklists_listing.user_id,
                    checklists_listing.card_id,
                    checklists_listing.name,
                    checklists_listing.checklist_item_count,
                    checklists_listing.checklist_item_completed_count,
                    checklists_listing."position",
                    checklists_listing.checklists_items
                   FROM checklists_listing checklists_listing
                  WHERE (checklists_listing.card_id = cards.id)
                  ORDER BY checklists_listing.id) cc) AS cards_checklists,
    ( SELECT array_to_json(array_agg(row_to_json(cc.*))) AS array_to_json
           FROM ( SELECT cards_users_listing.username,
                    cards_users_listing.profile_picture_path,
                    cards_users_listing.id,
                    cards_users_listing.created,
                    cards_users_listing.modified,
                    cards_users_listing.card_id,
                    cards_users_listing.user_id,
                    cards_users_listing.initials,
                    cards_users_listing.full_name,
                    cards_users_listing.email
                   FROM cards_users_listing cards_users_listing
                  WHERE (cards_users_listing.card_id = cards.id)
                  ORDER BY cards_users_listing.id) cc) AS cards_users,
    ( SELECT array_to_json(array_agg(row_to_json(cv.*))) AS array_to_json
           FROM ( SELECT card_voters_listing.id,
                    card_voters_listing.created,
                    card_voters_listing.modified,
                    card_voters_listing.user_id,
                    card_voters_listing.card_id,
                    card_voters_listing.username,
                    card_voters_listing.role_id,
                    card_voters_listing.profile_picture_path,
                    card_voters_listing.initials,
                    card_voters_listing.full_name
                   FROM card_voters_listing card_voters_listing
                  WHERE (card_voters_listing.card_id = cards.id)
                  ORDER BY card_voters_listing.id) cv) AS cards_voters,
    ( SELECT array_to_json(array_agg(row_to_json(cs.*))) AS array_to_json
           FROM ( SELECT cards_subscribers.id,
                    to_char(cards_subscribers.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
                    to_char(cards_subscribers.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
                    cards_subscribers.card_id,
                    cards_subscribers.user_id,
                    (cards_subscribers.is_subscribed)::integer AS is_subscribed
                   FROM card_subscribers cards_subscribers
                  WHERE (cards_subscribers.card_id = cards.id)
                  ORDER BY cards_subscribers.id) cs) AS cards_subscribers,
    ( SELECT array_to_json(array_agg(row_to_json(cl.*))) AS array_to_json
           FROM ( SELECT cards_labels.label_id,
                    cards_labels.card_id,
                    cards_labels.list_id,
                    cards_labels.board_id,
                    cards_labels.name,
                    cards_labels.color
                   FROM cards_labels_listing cards_labels
                  WHERE (cards_labels.card_id = cards.id)
                  ORDER BY cards_labels.name) cl) AS cards_labels,
    cards.comment_count,
    u.username,
    b.name AS board_name,
    l.name AS list_name,
    cards.custom_fields,
    cards.color,
    cards.due_date AS notification_due_date,
    cards.is_due_date_notification_sent
   FROM (((cards cards
     LEFT JOIN users u ON ((u.id = cards.user_id)))
     LEFT JOIN boards b ON ((b.id = cards.board_id)))
     LEFT JOIN lists l ON ((l.id = cards.list_id)));

CREATE OR REPLACE VIEW lists_listing AS
SELECT lists.id,
    to_char(lists.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
    to_char(lists.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
    lists.board_id,
    lists.name,
    lists."position",
    (lists.is_archived)::integer AS is_archived,
    lists.card_count,
    lists.lists_subscriber_count,
    ( SELECT array_to_json(array_agg(row_to_json(lc.*))) AS array_to_json
           FROM ( SELECT cards_listing.id,
                    cards_listing.created,
                    cards_listing.modified,
                    cards_listing.board_id,
                    cards_listing.list_id,
                    cards_listing.name,
                    cards_listing.description,
                    cards_listing.due_date,
                    cards_listing.to_date,
                    cards_listing."position",
                    ((cards_listing.is_archived)::boolean)::integer AS is_archived,
                    cards_listing.attachment_count,
                    cards_listing.checklist_count,
                    cards_listing.checklist_item_count,
                    cards_listing.checklist_item_completed_count,
                    cards_listing.label_count,
                    cards_listing.cards_user_count,
                    cards_listing.cards_subscriber_count,
                    cards_listing.card_voter_count,
                    cards_listing.activity_count,
                    cards_listing.user_id,
                    cards_listing.title,
                    cards_listing.start,
                    cards_listing."end",
                    cards_listing.cards_checklists,
                    cards_listing.cards_users,
                    cards_listing.cards_voters,
                    cards_listing.cards_subscribers,
                    cards_listing.cards_labels,
                    cards_listing.comment_count,
                    cards_listing.custom_fields,
                    cards_listing.color,
                    cards_listing.due_date AS notification_due_date,
                    cards_listing.is_due_date_notification_sent
                   FROM cards_listing cards_listing
                  WHERE (cards_listing.list_id = lists.id)
                  ORDER BY cards_listing."position") lc) AS cards,
    ( SELECT array_to_json(array_agg(row_to_json(ls.*))) AS array_to_json
           FROM ( SELECT lists_subscribers.id,
                    to_char(lists_subscribers.created, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS created,
                    to_char(lists_subscribers.modified, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS modified,
                    lists_subscribers.list_id,
                    lists_subscribers.user_id,
                    (lists_subscribers.is_subscribed)::integer AS is_subscribed
                   FROM list_subscribers lists_subscribers
                  WHERE (lists_subscribers.list_id = lists.id)
                  ORDER BY lists_subscribers.id) ls) AS lists_subscribers,
    lists.custom_fields,
    lists.color
   FROM lists lists;