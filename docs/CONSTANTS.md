# Constants

- Constants in Rails applications are the subject of much debate in the forums. The understanding of what should be constant varies widely.
- The context for this application includes:
   * Engineering and scientific constants that are indepedent of the application
   * Role based access control (RBAC) system
- The commonly used options for implementing constants are:
   1 Hard code constants in the application, usually in model definitions.
      - Pro:
         - Speed: fast to access - predefined variables
         - Simple for developer to write and understand
      - Con:
         - Obscure to other developers
         - Not flexible: Requires code change and restart server to modify
   2 Hard code constants in the application configuration (usually in initializer files).
      - Pro:
         - Speed: moderately fast to access - lookup hash required
         - Simple for non-developer to provide modifications
      - Con:
         - Not flexible: Requires code change and restart server to modify
   3 Use database content.
      - Pro:
         - User can provide modifications
      - Con:
         - Speed: slow - requires database lookup for every constant access
         - Requires UI code for each use case

- The application implements a constants management system based on this article: [https://dev.to/vladhilko/say-goodbye-to-messy-constants-a-new-approach-to-moving-constants-away-from-your-model-58i1](https://dev.to/vladhilko/say-goodbye-to-messy-constants-a-new-approach-to-moving-constants-away-from-your-model-58i1).
- This system uses YAML files to store the constants. YAML files follow a fairly simple structure that can be learned by non-developers, enabling users to contribute to maintenance of the application.
- The system runs at server startup, and initializes a Constant::Model class object with the constants from the YAML files. This object is available as a global constant Constants. It is a singleton object, and is initialized only once.
- The code has been tweaked to allow the hash parsing to end on an array as well as a hash. This allows arrays for floating point numbers (primarily for electrical selectors).
- The initializer will include all correctly formatted files found under config/constants. Contributers to constants are required to ensure that keys don't clash.
- Usage:
  - Constants.electrical.protection.rating yields an array: [1, 2, 4, 6, 10, 16, 20, 25, 32, 40, 50, 63]
  - Constants.electrical.insulation_material yields a special hash: #<Constant::Model:0x000000012ee4eba0 @constant_hash={:PVC=>0, :XLPE=>1, :LSZH=>2, :EPR=>3, :PUR=>4}>. This can be converted to a basic hash if required with to_h.
