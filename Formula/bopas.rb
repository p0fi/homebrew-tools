require "download_strategy"
require "json"

# Downloads a release asset from a *private* GitHub repository using
# HOMEBREW_GITHUB_API_TOKEN.
#
# The formula `url` is the normal browser download URL so Homebrew names the
# cached file with the correct `.tar.gz` extension and unpacks it. At fetch
# time we resolve that to the asset's API URL and download it with
# `Accept: application/octet-stream` -- the only reliable way to pull assets
# from a private repository (the browser URL 404s for private repos). GitHub
# then redirects to a pre-signed URL; Homebrew's curl uses `--location` (not
# `--location-trusted`), so the token is dropped on the cross-host redirect.
class GitHubPrivateRepositoryReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    @github_token = ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", nil)
    return if @github_token.present?

    raise CurlDownloadStrategyError,
          "HOMEBREW_GITHUB_API_TOKEN is required to install #{name} from its private repository."
  end

  private

  def _fetch(url:, resolved_url:, timeout:)
    curl_download asset_api_url,
                  "--header", "Accept: application/octet-stream",
                  "--header", "Authorization: token #{@github_token}",
                  to: temporary_path, timeout: timeout
  end

  def asset_api_url
    match = @url.match(%r{^https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)$})
    raise CurlDownloadStrategyError, "Unexpected GitHub release URL: #{@url}" if match.nil?

    owner, repo, tag, filename = match.captures
    metadata = curl_output(
      "--header", "Accept: application/vnd.github+json",
      "--header", "Authorization: token #{@github_token}",
      "https://api.github.com/repos/#{owner}/#{repo}/releases/tags/#{tag}"
    ).stdout
    asset = JSON.parse(metadata).fetch("assets", []).find { |a| a["name"] == filename }
    raise CurlDownloadStrategyError, "No asset named #{filename} in #{owner}/#{repo}@#{tag}" if asset.nil?

    asset.fetch("url")
  end
end

class Bopas < Formula
  desc "Automate SAP time-entry creation via the SAP Fiori form"
  homepage "https://github.com/p0fi/bopas"
  version "2026-06-15"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/p0fi/bopas/releases/download/#{version}/bopas_darwin_arm64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "f808b854876511d41913ae80a32582a426d7263d61b832ec8793dbbf3c136647"
    end
    on_intel do
      url "https://github.com/p0fi/bopas/releases/download/#{version}/bopas_darwin_amd64.tar.gz",
          using: GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "03e263ef1e4e2d84b67947679ad2b84ea0d98da0ef092903e1aaeb5cbfca9f82"
    end
  end

  def install
    bin.install "bopas"
  end

  test do
    system bin/"bopas", "version"
  end
end
