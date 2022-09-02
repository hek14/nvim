; __init__ of class
(class_definition 
  body : (block
    (function_definition
      name: (identifier) @init_func (#eq? @init_func "__init__")
)))
;; you can capture something and use the exiting symbol such as: @type.builtin or @field or @boolean, then the highlighting for them will be used
;; all of the existing treesitter highlighting symbols are here: https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md#parser-configurations
