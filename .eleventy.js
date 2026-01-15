// .eleventy.js (merged + fixed)
const { DateTime } = require("luxon");
const slugify = require("slugify");
const path = require("path");
const pluginRss = require("@11ty/eleventy-plugin-rss");

// Helper: make slugs nice
function dashify(name) {
  return name
    .replace(/([a-z])([A-Z])/g, "$1-$2")
    .replace(/[_\s]+/g, "-")
    .replace(/([a-zA-Z])(?=\d)/g, "$1-")
    .replace(/-{2,}/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase();
}

module.exports = function (eleventyConfig) {
  // Plugins
    eleventyConfig.addPassthroughCopy("images");
  eleventyConfig.addPassthroughCopy("css");
  eleventyConfig.addPassthroughCopy("favicon");
  
  eleventyConfig.addPlugin(pluginRss);
  

  // Filters
  eleventyConfig.addFilter("date", (value, format = "yyyy-MM-dd") => {
    return DateTime.fromJSDate(new Date(value)).toFormat(format);
  });
  eleventyConfig.addFilter("slug", (str) =>
    slugify(str, { lower: true, strict: true })
  );
  eleventyConfig.addFilter("archiveFilter", () => true);

  // Global computed permalink for /recent/YYYY/MM/DD/slug/
  eleventyConfig.addGlobalData("eleventyComputed", {
    permalink: (data) => {
      if (
        data.page &&
        data.page.inputPath &&
        (data.page.inputPath.includes("/posts/") ||
          data.page.inputPath.includes("/recent/")) &&
        data.date
      ) {
        const dt = DateTime.fromJSDate(new Date(data.date));
        const year = dt.toFormat("yyyy");
        const month = dt.toFormat("MM");
        const day = dt.toFormat("dd");

        const rawName = path.basename(
          data.page.inputPath,
          path.extname(data.page.inputPath)
        );
        const strippedName = rawName.replace(/^\d{4}-\d{2}-\d{2}-/, "");
        const dashifiedSlug = dashify(strippedName);

        return `/recent/${year}/${month}/${day}/${dashifiedSlug}/index.html`;
      }
      return data.permalink;
    },
  });

  // Base post query: include both flat .md and nested index.md
  const POSTS_GLOB = ["recent/**/*.md"];

  // Collections
  eleventyConfig.addCollection("flatPosts", (api) => {
    return api
      .getFilteredByGlob(POSTS_GLOB)
      .filter((item) => !item.data.draft)
      // Prefer Eleventy’s built-in date when present
      .sort((a, b) => b.date - a.date);
  });

  // Alias "posts" to the same list (your feed can use either)
  eleventyConfig.addCollection("posts", (api) => {
    return api
      .getFilteredByGlob(POSTS_GLOB)
      .filter((item) => !item.data.draft)
      .sort((a, b) => b.date - a.date);
  });

  // Month list for archives
  eleventyConfig.addCollection("months", (api) => {
    const months = new Set();
    api.getFilteredByGlob(POSTS_GLOB).forEach((post) => {
      const date = DateTime.fromJSDate(new Date(post.date || post.data.date));
      months.add(date.toFormat("yyyy-MM"));
    });
    return Array.from(months).map((key) => {
      const [year, month] = key.split("-");
      return {
        year,
        month,
        label: DateTime.fromObject({ year: +year, month: +month }).toFormat(
          "LLLL yyyy"
        ),
      };
    });
  });

  // Years list for archives
  eleventyConfig.addCollection("years", (api) => {
    const years = new Set();
    api.getFilteredByGlob(POSTS_GLOB).forEach((post) => {
      const year = DateTime.fromJSDate(
        new Date(post.date || post.data.date)
      ).toFormat("yyyy");
      years.add(year);
    });
    return Array.from(years).map((year) => ({ year }));
  });

  return {
    dir: {
      input: ".",
      includes: "_includes",
      data: "_data",
      output: "output", // unify on _site
    },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
  };
};