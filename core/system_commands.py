import subprocess


class SystemCommands:

  @staticmethod
  def execute_command(command):
    try:
      result = subprocess.run(
          command, shell=True, capture_output=True, text=True, encoding="cp720"
      )
      output = result.stdout or result.stderr
      return output.strip() if output else "✓ Command executed."
    except Exception as e:
      return str(e)