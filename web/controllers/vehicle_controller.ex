defmodule EdgeBuilder.VehicleController do
  use EdgeBuilder.Web, :controller

  alias EdgeBuilder.Changemap
  alias EdgeBuilder.Models.Vehicle
  alias EdgeBuilder.Models.VehicleAttack
  alias EdgeBuilder.Models.VehicleAttachment

  plug Plug.Authentication, except: [:show]
  plug :action

  def new(conn, _params) do
    render conn, :new,
      title: "New Vehicle",
      vehicle: %Vehicle{} |> Vehicle.changeset(current_user_id(conn)),
      vehicle_attacks: [%VehicleAttack{} |> VehicleAttack.changeset],
      vehicle_attachments: [%VehicleAttachment{} |> VehicleAttachment.changeset]
  end

  def create(conn, params = %{"vehicle" => vehicle_params}) do
    changemap = %{
      root: Vehicle.changeset(%Vehicle{}, current_user_id(conn), vehicle_params),
      vehicle_attacks: child_changesets(params["attacks"], VehicleAttack),
      vehicle_attachments: child_changesets(params["attachments"], VehicleAttachment)
    }

    if Changemap.valid?(changemap)  do
      changemap = Changemap.apply(changemap)

      redirect conn, to: vehicle_path(conn, :show, changemap.root)
    else
      render conn, :new,
        title: "New Vehicle",
        vehicle: changemap.root,
        vehicle_attacks: (if Enum.empty?(changemap.vehicle_attacks), do: [%VehicleAttack{} |> VehicleAttack.changeset], else: changemap.vehicle_attacks),
        vehicle_attachments: (if Enum.empty?(changemap.vehicle_attachments), do: [%VehicleAttachment{} |> VehicleAttachment.changeset], else: changemap.vehicle_attachments),
        errors: changemap.root.errors
    end
  end

  defp child_changesets(params, child_model, instances \\ [])
  defp child_changesets(params, child_model, instances) when is_map(params) do
    params
    |> Map.values
    |> Enum.map(&(to_changeset(&1, child_model, instances)))
    |> Enum.reject(&child_model.is_default_changeset?/1)
  end
  defp child_changesets(_,_,_), do: []

  defp to_changeset(params = %{"id" => id}, model, instances) when not is_nil(id) do
    Enum.find(instances, &(to_string(&1.id) == to_string(id))) |> model.changeset(params)
  end
  defp to_changeset(params, model, _), do: model.changeset(struct(model), params)
end
