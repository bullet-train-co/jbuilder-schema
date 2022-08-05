# module JbuilderSchema
#   module Formatter
#     private
#
#     def _replace_nil_variables(code)
#       begin
#         eval(code)
#       rescue NoMethodError
#         data = _find_data(code)
#         line.gsub!(code, data.to_s)
#       end
#     end
#
#     def _find_data(string)
#       variable, method = string.split('.')
#       type = ObjectSpace.each_object(Class)
#                         .select { |c| c.name == variable.gsub('@', '').classify }.first
#                         .columns_hash[method].type
#       1
#     end
#
#     def _value_for_type(type)
#       case type
#       when Integer
#         1
#       when Boolean
#         false
#
#       end
#     end
#   end
# end