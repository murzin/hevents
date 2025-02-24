# Events API Documentation

This documentation describes the REST API endpoints for managing events, event types, event places, and event links.

## Base Endpoints

### Events

#### List All Events
- **GET** `/events`
- **Description**: Retrieves all events with their associated type and place information
- **Response**: Array of event objects with the following fields:
  - `evt_id`: Event ID
  - `evt_name`: Event name (UTF-8 encoded)
  - `evt_desc`: Event description
  - `evt_url`: Event URL
  - `evt_from`: Start date/time
  - `evt_to`: End date/time
  - `etp_id`: Event type ID
  - `epl_id`: Event place ID
  - `etp_name`: Event type name
  - `epl_name`: Event place name

#### Create Event
- **POST** `/events`
- **Description**: Creates a new event
- **Request Body**:
```json
{
    "evt_name": "string",
    "evt_desc": "string",
    "evt_url": "string",
    "evt_from": "datetime",
    "evt_to": "datetime",
    "etp_id": "integer",
    "epl_id": "integer"
}
```
- **Response**: `{ "id": "integer" }`

#### Get Event
- **GET** `/events/:id`
- **Description**: Retrieves a specific event by ID with type and place information
- **Parameters**: 
  - `id`: Event ID
- **Response**: Single event object or empty object if not found

#### Update Event
- **PUT** `/events/:id`
- **Description**: Updates an existing event
- **Parameters**:
  - `id`: Event ID
- **Request Body**: Same as Create Event
- **Response**: `{ "success": 1 }`

#### Delete Event
- **DELETE** `/events/:id`
- **Description**: Deletes an event
- **Parameters**:
  - `id`: Event ID
- **Response**: `{ "success": 1 }`

### Event Types

#### List Event Types
- **GET** `/event_types`
- **Description**: Retrieves all event types
- **Response**: Array of event type objects

#### Create Event Type
- **POST** `/event_types`
- **Description**: Creates a new event type
- **Request Body**:
```json
{
    "etp_name": "string"
}
```
- **Response**: `{ "id": "integer" }`

#### Get Event Type
- **GET** `/event_types/:id`
- **Description**: Retrieves a specific event type
- **Parameters**:
  - `id`: Event type ID
- **Response**: Event type object or empty object if not found

#### Delete Event Type
- **DELETE** `/event_types/:id`
- **Description**: Deletes an event type
- **Parameters**:
  - `id`: Event type ID
- **Response**: `{ "success": 1 }`

### Event Places

#### List Event Places
- **GET** `/event_places`
- **Description**: Retrieves all event places
- **Response**: Array of event place objects

#### Create Event Place
- **POST** `/event_places`
- **Description**: Creates a new event place
- **Request Body**:
```json
{
    "epl_name": "string"
}
```
- **Response**: `{ "id": "integer" }`

#### Get Event Place
- **GET** `/event_places/:id`
- **Description**: Retrieves a specific event place
- **Parameters**:
  - `id`: Event place ID
- **Response**: Event place object or empty object if not found

#### Delete Event Place
- **DELETE** `/event_places/:id`
- **Description**: Deletes an event place
- **Parameters**:
  - `id`: Event place ID
- **Response**: `{ "success": 1 }`

### Event Links

#### List Linked Events
- **GET** `/event_links/:event_id`
- **Description**: Retrieves all events linked to the specified event
- **Parameters**:
  - `event_id`: Event ID
- **Response**: Array of linked event objects

#### Create Event Link
- **POST** `/event_links`
- **Description**: Creates a link between two events
- **Request Body**:
```json
{
    "evt_id_1": "integer",
    "evt_id_2": "integer"
}
```
- **Response**: `{ "success": 1 }`

#### Delete Event Link
- **DELETE** `/event_links`
- **Description**: Removes a link between two events
- **Request Body**:
```json
{
    "evt_id_1": "integer",
    "evt_id_2": "integer"
}
```
- **Response**: `{ "success": 1 }`

## Data Models

### Event
```
{
    evt_id: integer      // Event ID
    evt_name: string     // Event name
    evt_desc: string     // Event description
    evt_url: string      // Event URL
    evt_from: datetime   // Start date/time
    evt_to: datetime     // End date/time
    etp_id: integer     // Event type ID
    epl_id: integer     // Event place ID
    etp_name: string    // Event type name
    epl_name: string    // Event place name
}
```

### Event Type
```
{
    etp_id: integer     // Event type ID
    etp_name: string    // Event type name
}
```

### Event Place
```
{
    epl_id: integer     // Event place ID
    epl_name: string    // Event place name
}
```

## Notes
- All responses are in JSON format
- Date/time fields should be provided in a format compatible with your database
- Success responses include either the new record ID or a success flag
- UTF-8 encoding is used for event names
