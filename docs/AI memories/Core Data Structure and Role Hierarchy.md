# Core Data Structure

### 1. Projects
- Top-level resource in the application
- Uniquely identified by 2-letter codes (e.g., AA, AB, AC)
- Serve as containers for all project-related resources
- Can be organized into stages (1-10)
- Associated with multiple disciplines through their resources

### 2. Tags
- Belong to projects
- Can be sub-grouped by project stage (1-10)
- Belong to disciplines (e.g., Electrical, Piping)
- Must be unique within disciplines and projects
- Can be used to construct tagable types (Switchboard, Motor, SocketCct, LightCct, Pipe, Source, Consumer)

### 3. Disciplines
- Used to group tags and documents
- Shared across the organization (same set for all projects)
- Interact with functional role assignments (HOLD)
- Managed via db:seed (no UI for management)

### 4. Electrical Module
- Models electrical power distribution
- **Note**: Originally the demand model was named load, but this caused conflict with the ruby keyword. If you see the words load, loadable or Load anywhere in an electrical context, flag for possible deletion.
- **Demandable Tag Types**:
  - Can be used to construct an associated demand
  - Types: Switchboard, Motor, SocketCct, LightCct
- **Switchboards**:
  - Have multiple outgoing circuits with protection devices
  - Each circuit can have an assigned load and cable
  - Use "summation" load type (aggregates loads of outgoing circuits)
