local M = {
  pyright = {
    enable = true,
    server = '',
    disableCompletion = false,
    disableDiagnostics = false,
    disableDocumentation = false,
    disableProgressNotifications = false,
    completion = {
      importSupport = true,
      snippetSupport = true,
    },
    organizeimports = {
      provider = 'pyright'
    },
    inlayHints = {
      functionReturnTypes = true,
      variableTypes = true,
    },
    testing = {
      provider = 'unittest',
      unittestArgs = {},
      pytestArgs = {},
    }
  },
  python = {
    analysis = {
      autoImportCompletions = true,
      autoSearchPaths = true,
      diagnosticMode = 'openFilesOnly',
      extraPaths = { vim.fn.expand("~/.config/nvim/bin/python/python-type-stubs/stubs") },
      typeshedPaths = {},
      diagnosticSeverityOverrides = {},
      typeCheckingMode = 'basic',
      useLibraryCodeForTypes = true,
    },
    pythonPath = 'python',
    venvPath = '',
    formatting = {
      provider = 'autopep8',
      blackPath = 'black',
      blackArgs = {},
      darkerPath = 'darker',
      darkerArgs = {},
      pyinkPath = 'pyink',
      pyinkArgs = {},
      blackdPath = 'blackd',
      blackdHTTPURL = "",
      blackdHTTPHeaders = {},
      yapfPath = 'yapf',
      yapfArgs = {},
      autopep8Path = 'autopep8',
      autopep8Args = {},
    },
    linting = {
      enabled = true,
      flake8Enabled = false,
      banditEnabled = false,
      mypyEnabled = false,
      ruffEnabled = false,
      pytypeEnabled = false,
      pycodestyleEnabled = false,
      prospectorEnabled = false,
      pydocstyleEnabled = false,
      pylamaEnabled = false,
      pylintEnabled = false,
      pyflakesEnabled = false,
    },
    sortImports = {
      path = '',
      args = {},
    }
  }
}

return M
