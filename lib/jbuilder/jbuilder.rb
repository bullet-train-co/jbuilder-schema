# TODO: Remove reliance on `require "jbuilder"` hitting our shadow file, instead of Jbuilder's own file:
# https://github.com/rails/jbuilder/blob/7ab0e3563c9ba1680fb8ffebafced529a8e25a5f/lib/jbuilder/jbuilder.rb#L3
#
# This shadowing means Jbuilder doesn't inherit from BasicObject when using jbuilder-schema, which may break assumptions in Jbuilder.
