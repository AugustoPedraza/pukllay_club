defmodule PukllayClub.DeploySecretsContractTest do
  @moduledoc """
  Keeps `config/deploy.yml`'s Kamal `env.secret` list and
  `.github/workflows/deploy.yml`'s `.kamal/secrets` heredoc + `Deploy with
  Kamal` step env block in sync with every credential
  `PukllayClub.Catalog.Seed.Credentials` resolves (D-02, 01.8.1-08) —
  except `R2_PUBLIC_BASE_URL`, which is already declared under
  `config/deploy.yml`'s `env.clear` (it is not a secret, per that file's
  own comment). Production enrichment (`Workers.EnrichGameWorker`) fails
  at every stage — BGG fetch, R2 upload, Gemini translation — if any of
  these is missing on the host (RESEARCH.md Pitfall 4); this test exists
  so adding a new required key to `Credentials` without also plumbing it
  through both deploy files fails the suite instead of failing silently in
  production.

  Reads both files as plain text — deliberately not a YAML/heredoc parser
  — since the property under test is "the name appears where staff expect
  it," not "the file has a particular structure."
  """
  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Seed.Credentials

  # R2_PUBLIC_BASE_URL is a Credentials key but is public (every stored
  # image URL already carries this exact host) — it lives under
  # config/deploy.yml's env.clear, not env.secret, and is deliberately
  # excluded from this contract.
  @already_clear "R2_PUBLIC_BASE_URL"
  @expected_secret_names Credentials.env_var_names() -- [@already_clear]

  @deploy_yml File.read!(Path.join(File.cwd!(), "config/deploy.yml"))
  @deploy_workflow File.read!(Path.join(File.cwd!(), ".github/workflows/deploy.yml"))

  test "the expected secret list has every Credentials key except R2_PUBLIC_BASE_URL" do
    refute @already_clear in @expected_secret_names
    assert "BGG_API_TOKEN" in @expected_secret_names
    assert "GEMINI_API_KEY" in @expected_secret_names
  end

  test "config/deploy.yml declares every expected credential under env.secret" do
    for name <- @expected_secret_names do
      assert @deploy_yml =~ name,
             "expected config/deploy.yml's env.secret list to declare #{name}"
    end
  end

  test ".github/workflows/deploy.yml carries every expected credential in both the .kamal/secrets heredoc and the Kamal deploy step's env block" do
    for name <- @expected_secret_names do
      occurrences =
        @deploy_workflow
        |> String.split(name)
        |> length()
        |> Kernel.-(1)

      assert occurrences >= 2,
             "expected #{name} to appear at least twice in .github/workflows/deploy.yml " <>
               "(once in the .kamal/secrets heredoc, once in the deploy step's env block) — found #{occurrences}"
    end
  end
end
