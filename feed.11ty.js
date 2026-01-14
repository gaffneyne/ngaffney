// feed.11ty.js
module.exports = class {
  data() {
    return {
      permalink: (data) => "/recent/feed.xml",
      layout: null,
      eleventyExcludeFromCollections: true,
      excludeFromCollections: true,
    };
  }

  render(data) {
    const siteUrl   = (data.site && data.site.url) || "https://ngaffney.net";
    const siteTitle = (data.site && data.site.title) || "ngaffney.net";
    const siteDesc  = (data.site && data.site.description) || "Photography and notes by Nicholas Gaffney.";
    const limit     = (data.site && data.site.feed && data.site.feed.limit) || 20;

    const posts = (data.collections.posts || data.collections.flatPosts || []).slice(0, limit);
    const last  = posts[0];
    const lastBuildDate = last ? new Date(last.date).toUTCString() : null;

    const esc = (s) => String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
    const abs = (u) => new URL(u, siteUrl).href;

    const itemsXml = posts.map(post => {
      const url   = abs(post.url);
      const title = esc(post.data.title || url);
      const pub   = new Date(post.date).toUTCString();
      const html  = String(post.templateContent || "");
      const desc  = post.data.description ? `  <description><![CDATA[${post.data.description}]]></description>\n` : "";
      return [
        "<item>",
        `  <title>${title}</title>`,
        `  <link>${url}</link>`,
        `  <guid isPermaLink="true">${url}</guid>`,
        `  <pubDate>${pub}</pubDate>`,
        desc + `  <description><![CDATA[${html}]]></description>`,
        "</item>"
      ].join("\n");
    }).join("\n");

    return `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
  xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>${esc(siteTitle)}</title>
    <link>${siteUrl}</link>
    <atom:link href="${siteUrl}/recent/feed.xml" rel="self" type="application/rss+xml"/>
    <description>${esc(siteDesc)}</description>
    <language>en</language>
    ${lastBuildDate ? `<lastBuildDate>${lastBuildDate}</lastBuildDate>` : ""}
${itemsXml}
  </channel>
</rss>`;
  }
};