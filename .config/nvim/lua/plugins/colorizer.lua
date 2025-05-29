return {
  {
    "norcalli/nvim-colorizer.lua",
    lazy = false,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("colorizer").setup({ "*" }, {
        RGB = true, -- highlight #RGB hex codes
        RRGGBB = true, -- highlight #RRGGBB hex codes
        names = true, -- highlight color names
        RRGGBBAA = false, -- highlight #RRGGBBAA hex codes (disable if not needed)
        rgb_fn = false, -- highlight css rgb() and rgba() functions
        hsl_fn = false, -- highlight css hsl() and hsla() functions
        css = true, -- highlight all CSS features (rgb_fn, hsl_fn, names, RRGGBBAA)
        css_fn = true, -- highlight CSS functions (rgb_fn, hsl_fn)
      })
    end,
  },
}
