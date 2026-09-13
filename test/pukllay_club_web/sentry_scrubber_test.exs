defmodule PukllayClubWeb.SentryScrubberTest do
  @moduledoc """
  Guards the data-egress policy for `Sentry.LiveViewHook` breadcrumbs.

  Two halves, both load-bearing and pulling in OPPOSITE directions:

    * user-typed values must NEVER reach Sentry (`nombre`/`value` are not
      credential-shaped, so the SDK default would let them straight through);
    * the event name and the param KEYS must ALWAYS survive, because they are
      the entire diagnostic payload for the clause-mismatch class this hook was
      added to catch (Sentry ELIXIR-1).

  A change that satisfies only one half — e.g. swapping the redaction for a
  `Map.drop/2`, or deleting the custom scrubber — passes half these tests and
  fails the other half. That is the point.
  """

  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  alias PukllayClubWeb.SentryScrubber

  @redacted Sentry.Scrubber.scrubbed_value()

  describe "scrub/1 removes user-typed values" do
    test "redacts a name submitted under \"nombre\" (the form-submit shape)" do
      scrubbed = SentryScrubber.scrub(%{event: "reserve", params: %{"nombre" => "Ana Pérez"}})

      assert scrubbed.params["nombre"] == @redacted
      refute inspect(scrubbed) =~ "Ana"
    end

    test "redacts a name submitted under \"value\" (the phx-blur shape)" do
      scrubbed =
        SentryScrubber.scrub(%{event: "validate-reservation", params: %{"value" => "Ana Pérez"}})

      assert scrubbed.params["value"] == @redacted
      refute inspect(scrubbed) =~ "Ana"
    end

    # `nombre` is the reason this module exists rather than the SDK default:
    # it looks nothing like a credential, so nothing in Sentry's own key list
    # would ever match it.
    test "a name is redacted at the top level too, not only nested under :params" do
      assert %{"nombre" => @redacted} = SentryScrubber.scrub(%{"nombre" => "Ana"})
    end

    test "redaction reaches arbitrarily deep, including through lists" do
      scrubbed =
        SentryScrubber.scrub(%{params: %{"rows" => [%{"nested" => %{"value" => "Ana"}}]}})

      refute inspect(scrubbed) =~ "Ana"
    end

    test "atom keys are matched as well as string keys" do
      assert %{nombre: @redacted, value: @redacted} =
               SentryScrubber.scrub(%{nombre: "Ana", value: "Ana"})
    end
  end

  describe "scrub/1 preserves the diagnostic payload" do
    # THE load-bearing assertion. Dropping the keys instead of their values
    # would leave `params: %{}` — indistinguishable from an event that carries
    # no params at all — and the hook would not have diagnosed ELIXIR-1 either.
    test "the param KEYS survive, so a clause mismatch stays diagnosable" do
      scrubbed =
        SentryScrubber.scrub(%{event: "validate-reservation", params: %{"value" => "Ana"}})

      assert Map.keys(scrubbed.params) == ["value"]
    end

    test "the event name survives verbatim" do
      scrubbed =
        SentryScrubber.scrub(%{event: "validate-reservation", params: %{"value" => "Ana"}})

      assert scrubbed.event == "validate-reservation"
    end

    test "non-sensitive params pass through untouched" do
      params = %{"id" => "10", "facet" => "mechanics", "choice" => "negociación"}

      assert SentryScrubber.scrub(%{event: "toggle-facet", params: params}).params == params
    end
  end

  describe "scrub/1 composes with, rather than replaces, the SDK defaults" do
    # `Sentry.Scrubber`'s `:keys` option OVERRIDES the default list. Splicing
    # `default_param_keys/0` back in is easy to lose in a refactor, and losing
    # it silently stops scrubbing credentials — which no other test here would
    # notice.
    test "credential-shaped keys are still redacted" do
      scrubbed = SentryScrubber.scrub(%{"password" => "hunter2", "secret" => "s3cr3t"})

      assert scrubbed == %{"password" => @redacted, "secret" => @redacted}
    end
  end

  describe "the hook is actually wired into every LiveView" do
    # Unit-testing the scrubber proves the policy is correct; this proves the
    # policy is REACHED. Without the `on_mount` in `PukllayClubWeb.live_view/0`
    # the scrubber is dead code and every test above still passes.
    test "a LiveView records Sentry breadcrumbs, and a blur breadcrumb keeps the event name and param key but not the typed name",
         %{conn: conn} do
      game = game_fixture()
      {:ok, view, _html} = live(conn, ~p"/juegos/#{game}")
      view |> element(".pk-poster-col button[phx-click='open-reservation']") |> render_click()
      render_blur(view, "validate-reservation", %{"value" => "Ana Pérez"})

      breadcrumbs = sentry_breadcrumbs(view.pid)

      assert Enum.any?(breadcrumbs, &(&1.category == "web.live_view.event")), """
      No LiveView event breadcrumb was recorded, so Sentry.LiveViewHook is not \
      attached. Check the on_mount in PukllayClubWeb.live_view/0.
      """

      blur =
        Enum.find(breadcrumbs, &(&1.category == "web.live_view.event" and &1.data[:event] == "validate-reservation"))

      assert blur, "the validate-reservation event produced no breadcrumb"
      assert Map.keys(blur.data[:params]) == ["value"]
      assert blur.data[:params]["value"] == @redacted
      refute inspect(breadcrumbs) =~ "Ana"
    end
  end

  # Sentry.Context keeps its per-process context in the OTP logger's process
  # metadata, so it can only be read from inside the owning process — hence the
  # dictionary peek rather than a `Sentry.Context.get_all/0` call, which would
  # read the TEST process and always come back empty.
  defp sentry_breadcrumbs(pid) do
    {:dictionary, dictionary} = Process.info(pid, :dictionary)

    dictionary
    |> Keyword.get(:"$logger_metadata$", %{})
    |> Map.get(Sentry.Context.__logger_metadata_key__(), %{})
    |> Map.get(:breadcrumbs, [])
    |> Enum.to_list()
  end
end
