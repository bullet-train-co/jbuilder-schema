# We can't use the standard `Jbuilder::Schema::VERSION =` because
# `Jbuilder` isn't a regular module namespace, but a class …which also loads Active Support.
# So we use trickery, and assign the proper version once `jbuilder/schema.rb` is loaded.
JBUILDER_SCHEMA_VERSION = "2.5.0"
