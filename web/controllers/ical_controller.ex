defmodule Butler.IcalController do
  use Butler.Web, :controller

  def index(conn, _params) do
    url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vT-cldaNaUXFu7XLT5i61GaXplDhFLXxNg9MydEsPPHEWnKcax7LY2Df8bibgwZjb3No4gNVFQCw-33/pub?gid=0&single=true&output=csv"
    
    response = HTTPoison.request!(:get, url, "", [], [follow_redirect: true]) 
    req = response.body
        
    IO.puts('>>>>>>>>>>>>><<<<<<<<<<<<<<')
    IO.puts(String.split(req, ~r/\R/) |> Enum.filter(fn (line) -> !Blankable.blank?(String.split(line, ~r/,/) |> Enum.at(1)) end) |> List.delete_at(0)|> List.delete_at(0))
    events = Enum.map(String.split(req, ~r/\R/) |> Enum.filter(fn (line) -> !Blankable.blank?(String.split(line, ~r/,/) |> Enum.at(1)) end) |> List.delete_at(0)|> List.delete_at(0), fn (event) ->
      string_to_ical(event)
    end)

    calendar_str = Enum.join(events, "\n")


    render(conn, "index.txt", calendar_str: calendar_str)
  end

  def string_to_ical(str) do
      list = String.split(str, ~r/,/)

      starts_at_date = Enum.at(list, 1)
      starts_at_time = Enum.at(list,6)
      ends_at_date = Enum.at(list, 1)
      ends_at_time = Enum.at(list, 7)

      IO.puts(str)
      IO.puts(starts_at_time)
      
      parsed_date_data = if Blankable.blank?(starts_at_time), do: parse_date_all_day(starts_at_date, starts_at_time, ends_at_date, ends_at_time), else: parse_date(starts_at_date, starts_at_time, ends_at_date, ends_at_time)      

      if parsed_date_data != false do
      'BEGIN:VEVENT
SUMMARY:#{Enum.at(list, 2)}
#{parsed_date_data}
DESCRIPTION: #{Enum.at(list, 3)}
END:VEVENT'
      else
        ''
      end
  end

  def parse_date(starts_at_date, starts_at_time, ends_at_date, ends_at_time) do
    try do
    starts_at = Timex.parse!("#{starts_at_date} #{starts_at_time}", "%-m/%-d/%Y %-I:%M %P", :strftime)
    ends_at = Timex.parse!("#{ends_at_date} #{ends_at_time}", "%-m/%-d/%Y %-I:%M %P", :strftime)
    parsed_starts_at = Timex.format!(starts_at, "TZID=America/Los_Angeles:%Y%m%dT%H%M00", :strftime)
    parsed_ends_at = Timex.format!(ends_at, "TZID=America/Los_Angeles:%Y%m%dT%H%M00", :strftime)
    "DTSTART;#{parsed_starts_at}
DTEND;#{parsed_ends_at}"
    rescue
      e -> false
    end
    end

    def parse_date_all_day(starts_at_date, starts_at_time, ends_at_date, ends_at_time) do
      try do
        starts_at = Timex.parse!("#{starts_at_date}", "%-m/%-d/%Y", :strftime)
        ends_at = Timex.parse!("#{ends_at_date}", "%-m/%-d/%Y", :strftime)
        parsed_starts_at = Timex.format!(starts_at, "VALUE=DATE:%Y%m%d", :strftime)
        parsed_ends_at = Timex.format!(ends_at, "VALUE=DATE:%Y%m%d", :strftime)
        "DTSTART;#{parsed_starts_at}
DTEND;#{parsed_ends_at}"
      rescue
        e -> false
      end
        end
end
