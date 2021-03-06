exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      // joinTo: "js/app.js"

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      joinTo: {
       "js/app.js": /^(js|..\/deps|node_modules)/,
       "js/landing.js": /^(landing_js|..\/deps|node_modules)/,
       // "js/help.js": /^(help_js|..\/deps|node_modules)/,
       "js/adapter.js": ["vendor/adapter.js"],
       "js/textarea-autogrow.js": ["vendor/textarea-autogrow.js"],
       "js/frameworks.js": ["vendor/frameworks.js"],
       "js/application.js": ["vendor/application.js"],
       "js/wiki.js": ["vendor/wiki.js"]
       // "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      },
      //
      // To change the order of concatenation of files, explicitly mention here
      order: {
        before: [
          "js/one_chat.js"
        ],
        after: [
          "js/typing.js"
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": [
          /^(css)/,
          "node_modules/highlight.js/styles/solarized-dark.css",
          "node_modules/sweetalert/dist/sweetalert.css",
          "../plugins/one_admin/priv/static/one_admin.scss"
          // "node_modules/emojionearea/dist/emojionearea.min.css",

        ],
        "css/channel_settings.css": ["scss/channel_settings.scss"],
        "css/help.css": ["scss/help.scss", "scss/components.scss"],
        "css/toastr.css": ["css/toastr.css"],
        "css/emojipicker.css": ["vendor/emojiPicker.css"],
        "css/one_pages.css": [
          "../plugins/one_pages/priv/static/css/one_pages.css"
        ]
        // "css/toastr.css": ["web/static/scss/toastr.scss"]
      },
      order: {
        // after: ["web/static/css/theme/main.scss", "web/static/css/app.css"] // concat app.css last
        // after: ["web/static/css/livechat.scss", "web/static/css/app.css"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: [
      /^(static)/,
      "../plugins/one_pages/assets/static"
    ]
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "static",
      "fonts",
      "css",
      "js",
      "help_js",
      "vendor",
      "scss", "../plugins/one_admin/priv/static",
      "../plugins/one_pages/priv/static",
    ],
    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    },
    postcss: {
      processors: [
        require("autoprefixer")
      ]
    },
    sass: {
      mode: "native", // This is the important part!
      options: {
        // includePaths: [ 'node_modules' ]
      }
    },
    coffeescript: {
      // bare: true
    },
    // copycat: {
    //   "fonts": ["node_modules/infinity_one_pages/priv/dist/fonts"],
    //   "images": ["node_modules/infinity_one_pages/priv/dist/images"],
    //   // "js": ["node_modules/infinity_one_pages/priv/dist/js"],
    //   "css": ["node_modules/infinity_one_pages/priv/dist/css"],
    //   verbose: false,
    //   onlyChanged: true
    // },
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    // whitelist: ["one_admin"],
    styles: {
      // toastr: ["toastr.css"],
      "highlight.js": ['styles/solarized-dark.css'],
      sweetalert: ['dist/sweetalert.css'],
      // infinity_one_pages: ['css/infinity_one_pages.css']
      // one_admin: ['priv/static/one_admin.scss']  // this isn't working
      // emojionearea: ['dist/emojionearea.min.css']
      // emojipicker: ['dist/emojipicker.css']
    },
    globals: {
      sweetAlert: 'sweetalert',
      // $: 'jquery',
      // JQuery: 'jquery',
      _: 'underscore'
    }
  }
};
