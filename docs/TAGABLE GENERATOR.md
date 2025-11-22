# TAGABLE GENERATOR

## INTRODUCTION

The application Project Assistant (PA) provides shared functionality for all types of engineering design elements within a project. The tag is the linkage for all pertinent information about the element. The name tags originated because identifying tags containing this core information were physically attached to the element. In this application, the tag model contains the core information about the element, required for all tags across all disciplines.

* Tags:

  * Tag number: it is a compound structure of prefix, serial number, and optional suffix. This structure is not universal but very common in engineering practice.
  * Service description: a brief description of the function of the element.
  * Discipline: the discipline to which the tag belongs. In this application, disciplines are unique to projects, so the discipline is the link to the project for a tag.
  * Stage: the stage is a mechanism to allow grouping tags within a project. It can be used at the project's discretion.
  * Location: the physical location field also allows grouping of tags.

* Tagables:

  * The next level of information for elements is referenced in this application as the tagable data. This is not engineering terminology, it is Rails convention naming for delegated types (also for polymorphic associations, of which delegated types are a special case). Delegated type is a Rails database concept allowing disparate model types to share common data.
  * A note about spelling: Many sources claim that the correct spelling is taggable, including material written by DHH himself. However, tagable is the convention rails uses for a delegated type from tag, so we have gone with that rather than override convention.
  * Tagables are the first level of separation of information after the tag, as different elements will require different information. E.g. within the electrical discipline, a motor will require different information than a switchboard.
  * The tagable model can be considered to be the datasheet for the element type.
  * The tagable model should incorporate all information required to specify the element for purchase.

* Tagable types:

  * As the application grows to cover more different design elements, the number of tagable types will grow significantly.
  * Although the underlying models for different types of elements may not have much in common, the user actions associated with creating, editing, viewing and deleting them are very consistent.
  * To avoid repetition of development effort, the tagable models have been abstracted where possible.
  * This is applicable to controllers, policies, and their associated tests.

* Modules

  * Each discipline has a module associated with it.
  * The module provides a "namespace" which is rails terminology, meaning that names within the module must be unique, but can be the same as names in other modules.
  * A generator is provided for creating all the file structure and edits required for a new module.

* Tagables Generator

  * The subject of this document is the proposed tagables generator.
  * The generator will create the files and edits required to add a new tagable type.

