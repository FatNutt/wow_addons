import argparse
import os
import sys


def list_folders(path):
    """List all folders in the given path."""
    try:
        return [f for f in os.listdir(path) if os.path.isdir(os.path.join(path, f))]
    except FileNotFoundError:
        print('The specified path does not exist.')
        sys.exit(1)


def create_symlinks(selected_folders, source_path, dest_path):
    """Create symlinks for the selected folders in the destination path."""
    for folder in selected_folders:
        src = os.path.join(source_path, folder)
        dst = os.path.join(dest_path, folder)
        try:
            os.symlink(src, dst)
            print(f'✓ Created symlink: {dst} -> {src}')
        except FileExistsError:
            print(f'✗ Symlink already exists: {dst}')
        except Exception as e:
            print(f'✗ Error creating symlink for {folder}: {e}')


def main():
    parser = argparse.ArgumentParser(
        description='Create symlinks for selected folders.'
    )
    parser.add_argument(
        'destination', type=str, help='The destination path to create symlinks.'
    )

    args = parser.parse_args()

    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Define source path relative to script location
    # Example: ../plugins/ or ./plugins/
    source_path = os.path.join(script_dir, '../apps')
    source_path = os.path.abspath(source_path)  # Normalize the path

    # Get all folders
    folders = list_folders(source_path)

    if not folders:
        print('No folders found in the source path.')
        sys.exit(0)

    # Display available folders
    print('\n📁 Available plugins:')
    for idx, folder in enumerate(folders, 1):
        print(f'  {idx}: {folder}')

    # Prompt user for selection
    print("\nSelect plugins by number (comma-separated, e.g., '1,2,3'):")
    selections = input('> ').strip()

    if not selections:
        print('No selection made.')
        sys.exit(0)

    # Parse selections
    selected_indices = []
    for item in selections.split(','):
        item = item.strip()
        if item.isdigit():
            selected_indices.append(int(item) - 1)

    # Validate and get selected folders
    selected_folders = [folders[i] for i in selected_indices if 0 <= i < len(folders)]

    if not selected_folders:
        print('No valid selections made.')
        sys.exit(0)

    print(f'\n🔗 Creating {len(selected_folders)} symlink(s)...')
    create_symlinks(selected_folders, source_path, args.destination)
    print('\n✓ Done!')


if __name__ == '__main__':
    main()
