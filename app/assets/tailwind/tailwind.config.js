module.exports = {
  content: {
    relative: true,
    files: [
      // Panda Core views and components
      "../../app/views/**/*.html.erb",
      "../../app/components/**/*.html.erb",
      "../../app/components/**/*.rb",
      "../../app/helpers/**/*.rb",

      // Panda CMS views and components (for compilation)
      "../../../cms/app/views/**/*.html.erb",
      "../../../cms/app/builders/**/*.rb",
      "../../../cms/app/components/**/*.html.erb",
      "../../../cms/app/components/**/*.rb",
      "../../../cms/app/helpers/**/*.rb",
      "../../../cms/app/javascript/**/*.js",
      "../../../cms/vendor/javascript/**/*.js",
    ],
  },
  safelist: [
    // Tree indentation classes used in pages/index
    'ml-4',
    'ml-8',
    'ml-12',
    'ml-16',
    'ml-24',
  ],
};
