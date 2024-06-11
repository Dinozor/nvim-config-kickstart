return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "olimorris/neotest-phpunit",
        "nvim-neotest/nvim-nio",
    },
    config = function()
        require("neotest").setup({
            adapters = {
                require("neotest-phpunit")
            },
        })
        require("neotest-phpunit")({
            phpunit_cmd = function()
                return "vendor/bin/phpunit"
            end
        })
    end
}
