return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      nix = { "nixpkgs_fmt" },
      sml = { "smlfmt" },
    },
    formatters = {
      smlfmt = {
        command = "smlfmt",
        stdin = true,
      },
    },
  },
}
