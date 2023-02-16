defmodule WebBaitWeb.MainLiveTest do
  use WebBaitWeb.ConnCase

  import Phoenix.LiveViewTest
  import WebBait.DashboardsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_main(_) do
    main = main_fixture()
    %{main: main}
  end

  describe "Index" do
    setup [:create_main]

    test "lists all main", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.main_index_path(conn, :index))

      assert html =~ "Listing Main"
    end

    test "saves new main", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.main_index_path(conn, :index))

      assert index_live |> element("a", "New Main") |> render_click() =~
               "New Main"

      assert_patch(index_live, Routes.main_index_path(conn, :new))

      assert index_live
             |> form("#main-form", main: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#main-form", main: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.main_index_path(conn, :index))

      assert html =~ "Main created successfully"
    end

    test "updates main in listing", %{conn: conn, main: main} do
      {:ok, index_live, _html} = live(conn, Routes.main_index_path(conn, :index))

      assert index_live |> element("#main-#{main.id} a", "Edit") |> render_click() =~
               "Edit Main"

      assert_patch(index_live, Routes.main_index_path(conn, :edit, main))

      assert index_live
             |> form("#main-form", main: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#main-form", main: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.main_index_path(conn, :index))

      assert html =~ "Main updated successfully"
    end

    test "deletes main in listing", %{conn: conn, main: main} do
      {:ok, index_live, _html} = live(conn, Routes.main_index_path(conn, :index))

      assert index_live |> element("#main-#{main.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#main-#{main.id}")
    end
  end

  describe "Show" do
    setup [:create_main]

    test "displays main", %{conn: conn, main: main} do
      {:ok, _show_live, html} = live(conn, Routes.main_show_path(conn, :show, main))

      assert html =~ "Show Main"
    end

    test "updates main within modal", %{conn: conn, main: main} do
      {:ok, show_live, _html} = live(conn, Routes.main_show_path(conn, :show, main))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Main"

      assert_patch(show_live, Routes.main_show_path(conn, :edit, main))

      assert show_live
             |> form("#main-form", main: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#main-form", main: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.main_show_path(conn, :show, main))

      assert html =~ "Main updated successfully"
    end
  end
end
