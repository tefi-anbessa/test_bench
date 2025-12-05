# Constants

## Implementation Choice

Constants in Rails applications are the subject of much debate in the forums. The understanding of what should be constant varies widely.
The context for this application includes:
   * Engineering and scientific constants that are indepedent of the application
   * Role based access control (RBAC) system
   * System configuration
   
The commonly used options for implementing constants are:
1. Hard code constants in the application, usually in model definitions.
   - Pro:
      - Speed: fast to access - predefined variables
      - Simple for developer to initially write and understand
   - Con:
      - Obscure to other developers, high maintenance cost
      - Completely opaque to users who may have a stake in the constants requirements.
      - Not flexible: Requires code change and restart server to modify
1. Hard code constants in the application configuration (usually in initializer files).
   - Pro:
      - Speed: moderately fast to access - lookup hash required
      - Simple for non-developers to provide requirements and modifications
   - Con:
      - Not particularly flexible: Requires file change and restart server to modify
1. Use database content.
   - Pro:
      - User can provide modifications
   - Con:
      - Speed: slow - requires database lookup for every constant access
      - Requires UI code for each use case

- The application implements a constants management system based on this article: [say-goodbye-to-messy-constants by vladhilko](https://dev.to/vladhilko/say-goodbye-to-messy-constants-a-new-approach-to-moving-constants-away-from-your-model-58i1).
- This system uses YAML files to store the constants. YAML files follow a fairly simple structure that can be learned by non-developers, enabling users to contribute to maintenance of the application.
- The system runs at server startup, and initializes a Constant::Model class object with the constants from the YAML files. This object is available as a global constant called Constants. It is a singleton object, and is initialized only once.
- The code has been tweaked to allow the hash parsing to end on an array as well as a hash. This allows arrays for floating point numbers (primarily for electrical selectors).
- The initializer will include all correctly formatted files found under config/constants. Contributers to constants are required to ensure that keys don't clash.

## Usage

In this application, constants have been used for a variety of cases.

### Role Based Access Control

The role based access control system uses constants to restrict the allowed role names. This ensures consistent usage and simple understanding. Systems where users can define new roles soon get out of hand.

Roles are defined in 
`config/constants/role.yml`
and the Role class implements helper methods such as 
`valid_roles_for(resource_type = nil, _resource_id = nil)`
for building the RBAC UI.

### Disciplines

Disciplines are an edge case for constants. The application originally hard coded disciplines, then switched to a database model with no UI. As the concept developed, and the need for improved isolation between projects became apparent, it was realized that disciplines were a suitable vehicle for allowing projects to customize themselves to suit end user requirements. Disciplines are a means of grouping engineering objects such as documents and tags, but their functionality has been extended here. Prefix schema, associated functional modules, and form colour swatches are linked to discipline.

Projects must define their own set of disciplines, but this can be done simply by adding 'standard' disciplines such as Instrument and Electrical, and this is the recommended usage. However, the project is free to modify the standard disciplines to suit requirements, or indeed generate new disciplines from scratch. One use case is to use alternative translations of the discipline names and labels.

"Standard' disciplines are defined in 
`config/constants/discipline.yml`

### Prefixes

A fundamantal strength of the application is requiring tag prefixes to conform to a schema, to prevent proliferation of individual choices for the same object type. Historically different schemata have been used by different engineering companies and their disciplines, with the ISA standard 5.1 used for tagging instruments probably being the originator of the concept. This application allows each discipline on each project to define their own prefix schema, but provides a number of 'standard' schemata as well, which can be used as they are, or copied and modified. 

"Standard' prefix schemata are defined in 
`config/constants/prefix.yml`

### Tagables

The application uses tags as the core part of all engineering elements. Tags can have a "tagable" model attached, which extends the information linked to the tag, to include the specific information relevant to the type of element. The list of tag types or tagable models is retained in constants. This is largely managed by the system, and is not for user input.

`test_bench/config/constants/tagable.yml`

### Modules

Each module implemented has an associated constants file, where it saves the options for enumerated values, plus any other engineering contants that are not related to programming but are needed for the module's functionality. Enumerated values (enums) are used for populating drop down lists, which are widely used in the application to ensure ease of use and consistency of data.

For example, electrical module has constants for phase designation, protection: device/rating/curve/elcb, conductor materials, insulator materials, armour materials, motor type, and so on. These are stored in

`config/constants/electrical.yml`

Typical usage in a tagable form such as a switchboard circuit:
`Constants.electrical.protection.rating`
yields an array: 
`[1, 2, 4, 6, 10, 16, 20, 25, 32, 40, 50, 63]`
which can provide the values for a select field:

    <%= f.select :rating, 
      options_for_select(Constants.electrical.mcb_rating,
      selected: circuit.rating),
      { include_blank: t("form.none") } %>

`Constants.electrical.insulation_materials.to_h`
yields a hash:
```> Constants.electrical.insulation_materials.to_h```
```=> {:PVC=>0, :XLPE=>1, :LSZH=>2, :EPR=>3, :PUR=>4}```
which can be used in the `class: CableType` model definition of an insulation field:
```enum :insulation, insulation_materials, prefix: true```

