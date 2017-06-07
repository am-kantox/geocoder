defmodule GeocoderTest do
  use ExUnit.Case

  test "An address in New York" do
    {:ok, coords} = Geocoder.call("1991 15th Street, Troy, NY 12180")
    assert_new_york coords
  end

  test "An address in Belgium" do
    {:ok, coords} = Geocoder.call("Dikkelindestraat 46, 9032 Wondelgem, Belgium")
    assert_belgium coords
  end

  test "Reverse geocode" do
    {:ok, coords} = Geocoder.call({51.0775264, 3.7073382})
    assert_belgium coords
  end

  test "A list of results for an address in Belgium" do
    {:ok, coords} = Geocoder.call_list("Dikkelindestraat 46, 9032 Wondelgem, Belgium")
    assert_belgium_list(coords, true)
  end

  test "A list of results for coordinates" do
    {:ok, coords} = Geocoder.call_list({51.0775264, 3.7073382})
    assert_belgium_list(coords, false)
  end

  test "Explicit Geocode.GoogleMaps data: latlng" do
    {:ok, coords} = Geocoder.call(Geocoder.GoogleMaps.new({51.0775264, 3.7073382}))
    assert_belgium(coords)
  end

  test "Explicit Geocode.GoogleMaps data: address" do
    {:ok, coords} = Geocoder.call(Geocoder.GoogleMaps.new("Dikkelindestraat 46, 9032 Wondelgem, Belgium"))
    assert_belgium(coords)
  end

  test "Explicit Geocode.GoogleMaps list: latlng" do
    {:ok, coords} = Geocoder.call_list(Geocoder.GoogleMaps.new({51.0775264, 3.7073382}))
    assert is_list(coords)
    assert [head|tail] = coords
    assert is_list(tail)
    assert_belgium(head)
  end

  test "Explicit Geocode.GoogleMaps list: address" do
    {:ok, coords} = Geocoder.call_list(Geocoder.GoogleMaps.new("Dikkelindestraat 46, 9032 Wondelgem, Belgium"))
    assert is_list(coords)
    assert [head|_] = coords
    assert_belgium(head)
  end

  defp assert_belgium(coords) do
    bounds = coords |> Geocoder.Data.bounds

    # Bounds are not always returned
    assert (nil == bounds.bottom) || (bounds.bottom |> Float.round == 51)
    assert (nil == bounds.left) || (bounds.left |> Float.round == 4)
    assert (nil == bounds.right) || (bounds.right |> Float.round == 4)
    assert (nil == bounds.top) || (bounds.top |> Float.round == 51)

    location = coords |> Geocoder.Data.location
    assert (nil == location.street_number) || location.street_number == "46"
    assert (nil == location.street) || location.street == "Dikkelindestraat"
    assert (nil == location.city) || location.city == "Gent" || location.city == "Ghent"
    assert (nil == location.country) || location.country == "Belgium"
    assert (nil == location.country_code) || location.country_code |> String.upcase == "BE"
    assert (nil == location.postal_code) || location.postal_code == "9032"
    #      lhs:  "Dikkelindestraat, Wondelgem, Ghent, Gent, East Flanders, Flanders, 9032, Belgium"
    #      rhs:  "Dikkelindestraat 46, 9032 Gent, Belgium"
    assert (nil == location.formatted_address) || location.formatted_address |> String.match?(~r/Dikkelindestraat/)
    assert (nil == location.formatted_address) || location.formatted_address |> String.match?(~r/Gent/) || location.formatted_address |> String.match?(~r/Ghent/)
    assert (nil == location.formatted_address) || location.formatted_address |> String.match?(~r/9032/)
    assert (nil == location.formatted_address) || location.formatted_address |> String.match?(~r/Belgium/)

    %Geocoder.Coords{lat: lat, lon: lon} = coords |> Geocoder.Data.latlng
    assert lat |> Float.round == 51
    assert lon |> Float.round(1) == 3.7
  end

  defp assert_belgium_list(result, single) do
    assert is_list(result)
    assert [head|tail] = result
    assert (if single, do: tail |> Enum.empty?, else: not(tail |> Enum.empty?))
    assert_belgium(head)
  end

  defp assert_new_york(coords) do
    location = coords |> Geocoder.Data.location
    assert location.street_number == "1991"
    assert location.street == "15th Street"
    assert String.contains?(location.city, "Troy")
    assert location.county == "Rensselaer County"
    assert location.country_code |> String.upcase == "US"
    assert location.postal_code == "12180"
  end
end
