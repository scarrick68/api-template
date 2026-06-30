# Rake Task Command Pattern

Rake tasks in this project should stay thin and delegate implementation to command objects.

## Convention

- Implement rake task logic in a command class under `lib/tasks/commands/`.
- This keeps task code thin, easier to test, easier to evolve and clear that the commands are rake task related.
- Use explicit rake task arguments (for example `task :name, [:arg1, :arg2]`) instead of reading from `ENV`.
- Keep argument parsing in the rake task and pass normalized keyword args into the command object.

## Parameter style choice

- Prefer normal rake args over environment variables for task inputs.
- Rationale:
	- The task interface is explicit at the DSL level.
	- Call sites are easier to discover from `bin/rails -T` and task definitions.
	- Tests can call the command object with plain Ruby keyword args, no global env setup.
  - No ambiguity about env vars provided by the shell vs. env vars provided by the task DSL.

Examples:

- Preferred:
	- `bin/rails "data_artifacts:upload_local[tmp/file.ndjson,customer_accounts,v1,manual]"`
- Legacy env style (do not use):
	- `FILE=tmp/file.ndjson SCHEMA=customer_accounts bin/rails data_artifacts:upload_local`

## Why this pattern

- Easier to understand: task wiring and business logic are separated.
- Easier to test: command classes can be unit tested without running rake.
- Easier to evolve: changing logic does not require rewriting task DSL code.
- Easier to reuse: commands can be invoked from other scripts or tasks without duplicating logic.

- See examples in `lib/tasks/data_artifacts.rake` and `lib/tasks/commands/data_artifacts/upload_local_command.rb`.