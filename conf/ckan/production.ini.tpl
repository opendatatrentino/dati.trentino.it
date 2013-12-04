##
## CKAN - Pylons configuration
## Template configuration for dati.trentino.it (w/o keys)
##
## Check the documentation in 'doc/configuration.rst' or at the
## following URL for a description of what they do and the full list of
## available options:
##
## http://docs.ckan.org/en/latest/configuration.html
##
## The %(here)s variable will be replaced with the parent directory of this file
##

[DEFAULT]

## WARNING: This must be set to ``false`` in production
debug = false


[server:main]
use = egg:Paste#http
host = 0.0.0.0
port = 5000


[app:main]

## Base config for pylons
##------------------------------------------------------------
use = egg:ckan
full_stack = true
cache_dir = /tmp/%(ckan.site_id)s/


## Beaker configuration (session cookies)
##------------------------------------------------------------
beaker.session.key = ckan
beaker.session.secret = Base64EncodedStringHere=


## Instance UUID
##------------------------------------------------------------
app_instance_uuid = {00000000-0000-0000-0000-000000000000}


## repoze.who configuration
##------------------------------------------------------------
who.config_file = %(here)s/who.ini
who.log_level = warning
who.log_file = %(cache_dir)s/who_log.ini


## Database Settings
##------------------------------------------------------------
sqlalchemy.url = postgresql://ckan:password@127.0.0.1/ckan_default
# ckan.datastore.write_url = postgresql://ckan:password@127.0.0.1/ckan_datastore
# ckan.datastore.read_url = postgresql://ckan_ro:password@127.0.0.1/ckan_datastore


## Site Settings
##------------------------------------------------------------
ckan.site_url =


## Authorization Settings
##------------------------------------------------------------
ckan.auth.anon_create_dataset = false
ckan.auth.create_unowned_dataset = true
ckan.auth.create_dataset_if_not_in_organization = true
ckan.auth.user_create_groups = true
ckan.auth.user_create_organizations = true
ckan.auth.user_delete_groups = true
ckan.auth.user_delete_organizations = true
ckan.auth.create_user_via_api = false


## Search Settings
##------------------------------------------------------------
ckan.site_id = default
solr_url = http://ckan-db.local:8983/solr/ckan_20
#ckan.simple_search = 1


## Plugins Settings
##------------------------------------------------------------

## Note: Add ``datastore`` to enable the CKAN DataStore
##       Add ``pdf_preview`` to enable the resource preview for PDFs
##		Add ``resource_proxy`` to enable resorce proxying and get around the
##		same origin policy
ckan.plugins = stats text_preview recline_preview datitrentinoit datitrentinoit_form


## Front-End Settings
##------------------------------------------------------------
ckan.site_title = Dati Trentino
ckan.site_description = **Dati Aperti del Trentino**. Tutti i dati che cercavi del Sistema Trentino.
ckan.favicon = /images/icons/icon.png
ckan.site_logo = /base/images/ckan-logo.png
ckan.gravatar_default = identicon
ckan.preview.direct = png jpg gif
ckan.preview.loadable = html htm rdf+xml owl+xml xml n3 n-triples turtle plain atom csv tsv rss txt json

# package_hide_extras = for_search_index_only
# package_edit_return_url = http://another.frontend/dataset/<NAME>
# package_new_return_url = http://another.frontend/dataset/<NAME>
# ckan.recaptcha.publickey =
# ckan.recaptcha.privatekey =
# ckan.template_footer_end =


## Internationalisation Settings
##------------------------------------------------------------
ckan.locale_default = it
ckan.locale_order = it en de pt_BR ja cs_CZ ca es fr el sv sr sr@latin no sk fi ru pl nl bg ko_KR hu sa sl lv
ckan.locales_offered =
ckan.locales_filtered_out =


## Feeds Settings
##------------------------------------------------------------
ckan.feeds.authority_name =
ckan.feeds.date =
ckan.feeds.author_name =
ckan.feeds.author_link =


## Storage Settings
##------------------------------------------------------------
ofs.impl = pairtree
ofs.storage_dir = /path/to/data


## Activity Streams Settings
##------------------------------------------------------------
# ckan.activity_streams_enabled = true
# ckan.activity_list_limit = 31
# ckan.activity_streams_email_notifications = true
# ckan.email_notifications_since = 2 days


## Email settings
##------------------------------------------------------------
email_to = you@yourdomain.com
error_email_from = paste@localhost
smtp.server = localhost
smtp.starttls = False
# smtp.user = your_username@gmail.com
# smtp.password = your_password
# smtp.mail_from =


## Authorization settings
##------------------------------------------------------------
ckan.auth.user_create_groups = False
ckan.auth.user_create_organizations = False
ckan.auth.user_delete_groups = False
ckan.auth.user_delete_organizations = False


## Harvester settings
##------------------------------------------------------------
# ckan.harvest.mq.type = ampq
# ckan.harvest.mq.hostname = localhost
# ckan.harvest.mq.port = 5672
# ckan.harvest.mq.user_id = guest
# ckan.harvest.mq.password = guest
# ckan.harvest.mq.virtual_host = /


## Path to translations directory
##------------------------------------------------------------
# ckan.i18n_directory = /path/to/translations/


## Licenses file
##------------------------------------------------------------
# licenses_group_url = http://licenses.opendefinition.org/licenses/groups/ckan.json
# licenses_group_url = file:///path/to/my/local/json-list-of-licenses.json


## Logging configuration
##------------------------------------------------------------

[loggers]
keys = root, ckan, ckanext

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARNING
handlers = console

[logger_ckan]
level = INFO
handlers = console
qualname = ckan
propagate = 0

[logger_ckanext]
level = DEBUG
handlers = console
qualname = ckanext
propagate = 0

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(asctime)s %(levelname)-5.5s [%(name)s] %(message)s
