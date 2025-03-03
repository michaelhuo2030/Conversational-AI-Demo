import type { NextConfig } from 'next'
import createNextIntlPlugin from 'next-intl/plugin'
import createMDX from '@next/mdx'
// import remarkGfm from 'remark-gfm'

const withNextIntl = createNextIntlPlugin()

const nextConfig: NextConfig = {
  /* config options here */
  output: 'standalone',
  // Configure `pageExtensions` to include markdown and MDX files
  pageExtensions: ['js', 'jsx', 'md', 'mdx', 'ts', 'tsx'],
}

const withMDX = createMDX({
  // Add markdown plugins here, as desired
  options: {
    // @ts-expect-error remark-gfm is not typed
    remarkPlugins: [['remark-gfm', { strict: true, throwOnError: true }]],
    rehypePlugins: [],
  },
})

export default withNextIntl(withMDX(nextConfig))
