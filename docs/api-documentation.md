# Events Management API Documentation

## Base URL
`http://localhost:3000/api`

## Event Types Endpoints

### List Events
- **GET** `/events`
- Optional query parameters:
  - `from`: Filter events starting on or after this date (format: YYYY-MM-DD)
  - `to`: Filter events ending on or before this date (format: YYYY-MM-DD)
- Examples:
  - Get all events: `/events`
  - Get future events: `/events?from=2025-01-01`
  - Get past events: `/events?to=2024-12-31`
  - Get events in date range: `/events?from=2025-01-01&to=2025-12-31`
- Response format:
```json
[
  {
    "evt_id": 1,
    "evt_name": "Annual Conference",
    "evt_desc": "Annual tech conference with keynotes",
    "evt_url": "https://conference.example.com",
    "evt_from": "2025-06-01",
    "evt_to": "2025-06-03",
    "etp_id": 1,
    "etp_name": "Conference"
  }
]
```

### Get Single Event Type
- **GET** `/event_types/{id}`
- Returns single event type
- Response format:
```json
{
  "etp_id": 1,
  "etp_name": "Conference"
}
```

### Create Event Type
- **POST** `/event_types`
- Request body:
```json
{
  "etp_name": "Conference"
}
```
- Returns created event type with ID

### Update Event Type
- **PUT** `/event_types/{id}`
- Request body:
```json
{
  "etp_name": "Updated Conference"
}
```
- Returns updated event type

### Delete Event Type
- **DELETE** `/event_types/{id}`
- Returns success message
- Note: Will delete all associated events (cascade delete)

## Events Endpoints

### List Events
- **GET** `/events`
- Returns array of all events with their event type names
- Response format:
```json
[
  {
    "evt_id": 1,
    "evt_name": "Annual Conference",
    "evt_desc": "Annual tech conference with keynotes",
    "evt_url": "https://conference.example.com",
    "evt_from": "2025-06-01",
    "evt_to": "2025-06-03",
    "etp_id": 1,
    "etp_name": "Conference"
  }
]
```
### Get Single Event
- **GET** `/events/{id}`
- Returns single event with event type name and linked events
- Response format:
```json
{
  "evt_id": 1,
  "evt_name": "Annual Conference",
  "evt_desc": "Annual tech conference with keynotes",
  "evt_url": "https://conference.example.com",
  "evt_from": "2025-06-01",
  "evt_to": "2025-06-03",
  "etp_id": 1,
  "etp_name": "Conference",
  "linked_events": [
    {
      "evt_id": 2,
      "evt_name": "Workshop Day",
      "evt_desc": "Pre-conference workshop",
      "evt_url": "https://workshop.example.com",
      "evt_from": "2025-05-31",
      "evt_to": "2025-05-31",
      "etp_id": 2
    }
  ]
}
```

### Create Event
- **POST** `/events`
- Request body:
```json
{
  "evt_name": "Annual Conference",
  "evt_desc": "Annual tech conference with keynotes",
  "evt_url": "https://conference.example.com",
  "evt_from": "2025-06-01",
  "evt_to": "2025-06-03",
  "etp_id": 1
}
```
- Returns created event with ID

### Update Event
- **PUT** `/events/{id}`
- Request body format same as create
- Returns updated event

### Delete Event
- **DELETE** `/events/{id}`
- Returns success message

## Event Links Endpoints

### List Event Links
- **GET** `/events/{id}/links`
- Returns all events linked to the specified event
- Returns array of linked event objects

### Add Event Link
- **POST** `/events/{id}/links/{target_id}`
- Creates a link between two events
- No request body needed
- Returns success message

### Remove Event Link
- **DELETE** `/events/{id}/links/{target_id}`
- Removes link between two events
- Returns success message


## Response Status Codes
- 200: Success
- 201: Created (for POST requests)
- 400: Bad Request (invalid input)
- 404: Not Found
- 500: Server Error

## Data Types
- evt_id: Integer (auto-generated)
- evt_name: Text (required)
- evt_desc: Text (optional)
- evt_url: Text (optional)
- evt_from: Text (required, date format YYYY-MM-DD)
- evt_to: Text (required, date format YYYY-MM-DD)
- etp_id: Integer (required, must reference valid event type)
- etp_name: Text (required for event types)

## Error Response Format
```json
{
  "error": "Error message description"
}
```


# Events Management API Documentation

## Base URL
`http://localhost:3000/api`

## Events Endpoints

### Get Single Event
- **GET** `/events/{id}`
- Returns single event with event type name and linked events
- Response format:
```json
{
  "evt_id": 1,
  "evt_name": "Annual Conference",
  "evt_desc": "Annual tech conference with keynotes",
  "evt_url": "https://conference.example.com",
  "evt_from": "2025-06-01",
  "evt_to": "2025-06-03",
  "etp_id": 1,
  "etp_name": "Conference",
  "linked_events": [
    {
      "evt_id": 2,
      "evt_name": "Workshop Day",
      "evt_desc": "Pre-conference workshop",
      "evt_url": "https://workshop.example.com",
      "evt_from": "2025-05-31",
      "evt_to": "2025-05-31",
      "etp_id": 2
    }
  ]
}
```

## Event Links Endpoints

### List Event Links
- **GET** `/events/{id}/links`
- Returns all events linked to the specified event
- Returns array of linked event objects

### Add Event Link
- **POST** `/events/{id}/links/{target_id}`
- Creates a link between two events
- No request body needed
- Returns success message

### Remove Event Link
- **DELETE** `/events/{id}/links/{target_id}`
- Removes link between two events
- Returns success message

## Data Structure

### Event Links Table
Simple many-to-many relationship table with two columns:
- evt_id_1: First event ID (smaller ID of the pair)
- evt_id_2: Second event ID (larger ID of the pair)
- Primary key is (evt_id_1, evt_id_2)
