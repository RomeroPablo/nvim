; extends

; Preserve semantic roles when the upstream query also applies a broader
; @keyword capture to the same token.
((storage_class_specifier) @keyword.modifier
  (#set! priority 110))

((type_qualifier) @keyword.modifier
  (#set! priority 110))

([
  "explicit"
  "friend"
  "override"
] @keyword.modifier
  (#set! priority 110))

("decltype" @keyword.type
  (#set! priority 110))

("using" @keyword.type
  (#set! priority 110))

("requires" @keyword.operator
  (#set! priority 110))

("noexcept" @keyword.modifier
  (#set! priority 110))

; C++26 constructs not yet captured by the installed parser queries.
("export" @keyword.import
  (#set! priority 110))

("import" @keyword.import
  (#set! priority 110))

((type_identifier) @keyword.import
  (#eq? @keyword.import "module")
  (#set! priority 110))

((identifier) @keyword.modifier
  (#any-of? @keyword.modifier "pre" "post")
  (#set! priority 110))

((identifier) @keyword.assert
  (#eq? @keyword.assert "contract_assert")
  (#set! priority 110))
