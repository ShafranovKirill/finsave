defmodule FinsaveWeb.AuthLive.Login do
  use FinsaveWeb, :live_view
  alias Finsave.Identity

  defmodule LoginForm do
    use Ecto.Schema
    import Ecto.Changeset
    use Gettext, backend: FinsaveWeb.Gettext

    @type t :: %__MODULE__{}

    @primary_key false
    embedded_schema do
      field :email, :string
      field :password, :string
    end

    def changeset(data \\ %__MODULE__{}, attrs) do
      data
      |> cast(attrs, [:email, :password])
      |> validate_required([:email, :password], message: dgettext_noop("errors", "is required"))
      |> validate_format(:email, Identity.email_regex(),
        message: dgettext_noop("errors", "should be a email")
      )
      |> validate_format(:password, Identity.password_regex(),
        message:
          dgettext_noop(
            "errors",
            "must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character"
          )
      )
    end
  end

  def mount(_params, _session, socket) do
    if socket.assigns[:currenr_user] do
      {:ok, redirect(socket, to: "/dashboard")}
    else
      changeset = LoginForm.changeset(%{})

      {:ok,
       assign(socket,
         form: to_form(changeset, as: "user"),
         error_message: nil,
         trigger_action: false
       )}
    end
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      %LoginForm{}
      |> LoginForm.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "user"), error_message: nil)}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    changeset =
      %LoginForm{}
      |> LoginForm.changeset(params)
      |> Map.put(:action, :insert)

    if changeset.valid? do
      email = Ecto.Changeset.get_field(changeset, :email)

      case Identity.get_account_by_email(email) do
        {:ok, _account} ->
          {:no_reply, assign(socket, form: to_form(changeset, as: "user"), trigger_action: true)}

        {:error, :not_found} ->
          {:noreply,
           assign(socket,
             form: to_form(changeset, as: "user"),
             error_message: gettext("Invalid login or password")
           )}
      end
    else
      {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
    end
  end

  def render(assigns) do
    ~H"""
    """
  end
end
