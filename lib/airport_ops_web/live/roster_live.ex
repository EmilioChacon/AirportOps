defmodule AirportOpsWeb.RosterLive do
  use AirportOpsWeb, :live_view

  alias AirportOps.Operations
  alias AirportOps.Operations.Assignment

  @impl true
  def mount(_params, _session, socket) do
    # Only subscribe when the WebSocket is connected (skipping the initial static HTTP render)
    if connected?(socket) do
      Operations.subscribe_assignments()
    end

    flights = Operations.list_flights()
    agents = Operations.list_agents()
    assignments = Operations.list_assignments_with_associations()

    {:ok,
     socket
     |> assign(:page_title, "Airport Turnaround Coordinator")
     |> assign(:flights, flights)
     |> assign(:agents, agents)
     |> assign(:form, to_form(Operations.change_assignment(%Assignment{})))
     |> assign(:stats, compute_stats(flights, assignments))
     |> stream(:assignments, assignments)}
  end

  @impl true
  def handle_event("save_assignment", %{"assignment" => params}, socket) do
    case Operations.create_assignment(params) do
      {:ok, _assignment} ->
        {:noreply,
         socket
         |> clear_flash()
         |> put_flash(:info, "Turnaround shift assigned successfully!")
         |> assign(:form, to_form(Operations.change_assignment(%Assignment{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> clear_flash()
         |> put_flash(:error, "Failed to assign crew. Please check the form errors below.")
         |> assign(:form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event(
        "reassign_flight",
        %{"assignment-id" => assignment_id, "flight-id" => flight_id},
        socket
      ) do
    assignment = Operations.get_assignment!(assignment_id)

    case Operations.update_assignment(assignment, %{flight_id: flight_id}) do
      {:ok, _updated} ->
        {:noreply, put_flash(socket, :info, "Reassigned flight successfully!")}

      {:error, changeset} ->
        error_msg = extract_error_message(changeset)
        {:noreply, put_flash(socket, :error, "Reassignment failed: #{error_msg}")}
    end
  end

  @impl true
  def handle_event("delete_assignment", %{"id" => id}, socket) do
    assignment = Operations.get_assignment!(id)
    {:ok, _} = Operations.delete_assignment(assignment)
    {:noreply, put_flash(socket, :info, "Shift assignment deleted.")}
  end

  # PubSub Broadcast Handlers
  @impl true
  def handle_info({:assignment_created, assignment}, socket) do
    assignments = Operations.list_assignments_with_associations()

    {:noreply,
     socket
     |> stream_insert(:assignments, assignment, at: 0)
     |> assign(:stats, compute_stats(socket.assigns.flights, assignments))}
  end

  @impl true
  def handle_info({:assignment_updated, assignment}, socket) do
    assignments = Operations.list_assignments_with_associations()

    {:noreply,
     socket
     |> stream_insert(:assignments, assignment)
     |> assign(:stats, compute_stats(socket.assigns.flights, assignments))}
  end

  @impl true
  def handle_info({:assignment_deleted, assignment}, socket) do
    assignments = Operations.list_assignments_with_associations()

    {:noreply,
     socket
     |> stream_delete(:assignments, assignment)
     |> assign(:stats, compute_stats(socket.assigns.flights, assignments))}
  end

  defp compute_stats(flights, assignments) do
    turnarounds = Enum.count(flights, &(&1.status == "turnaround"))
    staff_on_shift = assignments |> Enum.map(& &1.agent_id) |> Enum.uniq() |> Enum.count()

    %{
      total_flights: length(flights),
      active_turnarounds: turnarounds,
      staff_on_shift: staff_on_shift
    }
  end

  defp extract_error_message(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
    |> Enum.join("; ")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        <%!-- Header Banner --%>
        <div class="flex flex-col md:flex-row md:items-center md:justify-between pb-6 border-b border-zinc-200 dark:border-zinc-800">
          <div>
            <div class="flex items-center gap-3">
              <span class="p-2 bg-blue-600 rounded-lg text-white font-bold text-xl tracking-wider">
                RampOps
              </span>
              <h1 class="text-3xl font-extrabold text-zinc-900 dark:text-zinc-50 tracking-tight">
                Turnaround Roster Coordinator
              </h1>
            </div>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              Live airport ground staff dispatch and 12-hour rest regulatory compliance monitor.
            </p>
          </div>

          <div class="mt-4 md:mt-0 flex items-center gap-3">
            <span class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800">
              <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              Live BEAM PubSub Connected
            </span>
          </div>
        </div>

        <%!-- Welcome Banner --%>
        <div class="bg-gradient-to-r from-blue-600 to-emerald-600 rounded-xl p-6 shadow-lg text-white mb-6">
          <h2 class="text-2xl font-bold flex items-center gap-2">
            <.icon name="hero-hand-raised" class="w-7 h-7" />
            Welcome to AirportOps!
          </h2>
          <p class="mt-2 text-blue-50 text-sm">
            This real-time Turnaround Shift Coordinator demonstrates the power of <strong>Elixir, Phoenix LiveView, and Ecto</strong>. 
            There's no heavy SPA framework here—just HTML-over-WebSockets delivering a snappy, stateful experience.
          </p>
          <ul class="mt-3 text-sm list-disc list-inside space-y-1 text-blue-100 font-medium">
            <li><strong>Try it out:</strong> Assign a new shift to Elena at Gate B12.</li>
            <li><strong>The 12-Hour Rest Rule:</strong> Try booking a shift that violates the mandatory 12-hour rest period to see the smart backend validation (via Ecto Changesets) kick in.</li>
            <li><strong>Real-time Sync:</strong> Open a second incognito browser window side-by-side to see PubSub sync the roster instantly.</li>
          </ul>
        </div>

        <%!-- Operational Stats KPI Cards --%>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
          <div class="bg-white dark:bg-zinc-900 rounded-xl p-5 border border-zinc-200 dark:border-zinc-800 shadow-xs">
            <p class="text-xs uppercase font-medium tracking-wider text-zinc-500">
              Scheduled Flights
            </p>
            <p class="mt-2 text-3xl font-bold text-zinc-900 dark:text-zinc-50">
              {@stats.total_flights}
            </p>
          </div>

          <div class="bg-white dark:bg-zinc-900 rounded-xl p-5 border border-blue-200 dark:border-blue-900/40 shadow-xs">
            <p class="text-xs uppercase font-medium tracking-wider text-blue-600 dark:text-blue-400">
              Active Turnarounds
            </p>
            <p class="mt-2 text-3xl font-bold text-blue-600 dark:text-blue-400">
              {@stats.active_turnarounds}
            </p>
          </div>

          <div class="bg-white dark:bg-zinc-900 rounded-xl p-5 border border-emerald-200 dark:border-emerald-900/40 shadow-xs">
            <p class="text-xs uppercase font-medium tracking-wider text-emerald-600 dark:text-emerald-400">
              Crew on Shift
            </p>
            <p class="mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-400">
              {@stats.staff_on_shift}
            </p>
          </div>
        </div>

        <%!-- Main Grid: Flights at Gates & Dispatch Console --%>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <%!-- Flights Turnaround Status --%>
          <div class="lg:col-span-1 space-y-4">
            <h2 class="text-lg font-bold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <.icon name="hero-paper-airplane" class="w-5 h-5 text-blue-600" /> Turnaround Gates
            </h2>

            <div class="space-y-3">
              <%= for flight <- @flights do %>
                <div class="bg-white dark:bg-zinc-900 rounded-xl p-4 border border-zinc-200 dark:border-zinc-800 shadow-xs hover:border-blue-300 transition-colors">
                  <div class="flex items-center justify-between">
                    <span class="text-lg font-black text-zinc-900 dark:text-zinc-50 tracking-wider">
                      {flight.flight_number}
                    </span>
                    <span class={[
                      "px-2.5 py-0.5 rounded-full text-xs font-semibold capitalize",
                      flight.status == "turnaround" &&
                        "bg-amber-100 text-amber-800 dark:bg-amber-950/70 dark:text-amber-300",
                      flight.status == "on_block" &&
                        "bg-blue-100 text-blue-800 dark:bg-blue-950/70 dark:text-blue-300",
                      flight.status == "scheduled" &&
                        "bg-zinc-100 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300"
                    ]}>
                      {flight.status}
                    </span>
                  </div>

                  <div class="mt-3 flex items-center justify-between text-xs text-zinc-600 dark:text-zinc-400">
                    <div>
                      <span class="font-semibold text-zinc-800 dark:text-zinc-200">{flight.origin}</span>
                      <span> &rarr; </span>
                      <span class="font-semibold text-zinc-800 dark:text-zinc-200">{flight.destination}</span>
                    </div>
                    <div class="font-mono bg-zinc-100 dark:bg-zinc-800 px-2 py-0.5 rounded">
                      Gate {flight.gate}
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Assignments Stream Table & Quick Reassignment --%>
          <div class="lg:col-span-2 space-y-4">
            <h2 class="text-lg font-bold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <.icon name="hero-user-group" class="w-5 h-5 text-emerald-600" />
              Live Shift Roster & Instant Reassignment
            </h2>

            <div class="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 shadow-xs overflow-hidden">
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800 text-sm">
                  <thead class="bg-zinc-50 dark:bg-zinc-800/50 text-zinc-600 dark:text-zinc-400 font-semibold text-xs uppercase tracking-wider">
                    <tr>
                      <th class="px-4 py-3 text-left">Agent</th>
                      <th class="px-4 py-3 text-left">Role</th>
                      <th class="px-4 py-3 text-left">Flight (Gate)</th>
                      <th class="px-4 py-3 text-left">Shift Time (UTC)</th>
                      <th class="px-4 py-3 text-left">Instant Reassign</th>
                      <th class="px-4 py-3 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody
                    id="assignments"
                    phx-update="stream"
                    class="divide-y divide-zinc-200 dark:divide-zinc-800"
                  >
                    <tr
                      :for={{id, assignment} <- @streams.assignments}
                      id={id}
                      class="hover:bg-zinc-50/50 dark:hover:bg-zinc-800/30 transition-colors"
                    >
                      <td class="px-4 py-3.5 font-medium text-zinc-900 dark:text-zinc-100 whitespace-nowrap">
                        {assignment.agent.name}
                      </td>
                      <td class="px-4 py-3.5 text-zinc-600 dark:text-zinc-400">
                        <span class="inline-block px-2 py-0.5 rounded bg-zinc-100 dark:bg-zinc-800 text-xs font-medium">
                          {assignment.role}
                        </span>
                      </td>
                      <td class="px-4 py-3.5 text-zinc-800 dark:text-zinc-200 font-mono text-xs">
                        {assignment.flight.flight_number} (Gate {assignment.flight.gate})
                      </td>
                      <td class="px-4 py-3.5 text-zinc-600 dark:text-zinc-400 text-xs font-mono whitespace-nowrap">
                        {Calendar.strftime(assignment.shift_start, "%b %d, %H:%M")} &rarr; {Calendar.strftime(
                          assignment.shift_end,
                          "%b %d, %H:%M"
                        )}
                      </td>
                      <td class="px-4 py-3.5">
                        <form
                          id={"reassign-form-#{assignment.id}"}
                          phx-change="reassign_flight"
                          class="inline-block"
                        >
                          <input type="hidden" name="assignment-id" value={assignment.id} />
                          <select
                            name="flight-id"
                            class="text-xs py-1 px-2 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 focus:ring-blue-500 focus:border-blue-500"
                          >
                            <%= for f <- @flights do %>
                              <option value={f.id} selected={f.id == assignment.flight_id}>
                                {f.flight_number} (Gate {f.gate})
                              </option>
                            <% end %>
                          </select>
                        </form>
                      </td>
                      <td class="px-4 py-3.5 text-right">
                        <button
                          phx-click="delete_assignment"
                          phx-value-id={assignment.id}
                          class="text-xs text-rose-600 hover:text-rose-800 font-medium px-2 py-1 rounded hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-colors"
                        >
                          Remove
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <%!-- New Shift Assignment Form (With Live 12-hour rest validation) --%>
            <div class="bg-zinc-50 dark:bg-zinc-900/60 rounded-xl p-5 border border-zinc-200 dark:border-zinc-800 space-y-4">
              <h3 class="text-sm font-bold uppercase tracking-wider text-zinc-700 dark:text-zinc-300 flex items-center gap-2">
                <.icon name="hero-plus-circle" class="w-4 h-4 text-blue-600" />
                Assign Ground Crew (12-Hour Rest Protected)
              </h3>

              <.form
                for={@form}
                id="assignment-form"
                phx-submit="save_assignment"
                class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 items-start"
              >
                <.input
                  field={@form[:agent_id]}
                  type="select"
                  label="Agent"
                  options={Enum.map(@agents, &{&1.name <> " (" <> &1.role <> ")", &1.id})}
                />

                <.input
                  field={@form[:flight_id]}
                  type="select"
                  label="Flight"
                  options={
                    Enum.map(@flights, &{&1.flight_number <> " (Gate " <> &1.gate <> ")", &1.id})
                  }
                />

                <.input
                  field={@form[:role]}
                  type="text"
                  label="Role"
                  value={@form[:role].value || "Marshaller"}
                  required
                />

                <.input
                  field={@form[:shift_start]}
                  type="datetime-local"
                  label="Shift Start (UTC)"
                  required
                />

                <.input
                  field={@form[:shift_end]}
                  type="datetime-local"
                  label="Shift End (UTC)"
                  required
                />

                <div class="h-full flex items-start pt-8">
                  <button
                    type="submit"
                    class="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-bold transition-colors"
                  >
                    Assign Crew
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
