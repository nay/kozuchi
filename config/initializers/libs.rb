# TODO: ビジネス版かで異なる。将来の制御のため本体はここに入れない。
require 'business'

ASSET_KINDS = Account::Asset::BASIC_KINDS.merge(defined?(EXTENSION_ASSET_KINDS) && EXTENSION_ASSET_KINDS[:business] ? EXTENSION_ASSET_KINDS[:business] : {})
def asset_kinds
  ASSET_KINDS.reject{|key, attributes| !yield(attributes)}.keys
end

