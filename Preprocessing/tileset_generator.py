from PIL import Image
import xml.etree.ElementTree as ET
import os

class TilesetCreator:
    def __init__(self, tile_size):
        self.tile_size = tile_size
        self.unique_tiles = {}
        self.next_id = 0

    def extract_unique_tiles(self, tilemap_path):
        """Extract unique tiles from a tilemap."""
        tilemap_img = Image.open(tilemap_path).convert('RGBA')  # Ensure the image is in RGBA mode
        tilemap_width = tilemap_img.width // self.tile_size
        tilemap_height = tilemap_img.height // self.tile_size
        
        for y in range(tilemap_height):
            for x in range(tilemap_width):
                tile = self.get_tile(tilemap_img, x, y)
                tile_data = tile.tobytes()
                if tile_data not in self.unique_tiles:
                    self.unique_tiles[tile_data] = (self.next_id, tile)
                    self.next_id += 1

    def get_tile(self, image, x, y):
        """Extract a tile from the specified position."""
        return image.crop((x * self.tile_size, y * self.tile_size,
                           (x + 1) * self.tile_size, (y + 1) * self.tile_size))

    def create_tileset_image(self, output_dir):
        """Create a tileset image from unique tiles."""
        num_tiles = len(self.unique_tiles)
        tiles_per_row = int(num_tiles**0.5) + 1
        tileset_img = Image.new('RGBA', (tiles_per_row * self.tile_size, (num_tiles // tiles_per_row + 1) * self.tile_size))
        
        x = y = 0
        for _, (tile_id, tile_img) in self.unique_tiles.items():
            tileset_img.paste(tile_img, (x * self.tile_size, y * self.tile_size))
            x += 1
            if x >= tiles_per_row:
                x = 0
                y += 1
        
        tileset_path = os.path.join(output_dir, "JugdralTileset.png")
        tileset_img.save(tileset_path)
        return tileset_path, num_tiles, tiles_per_row

    def generate_tsx(self, tileset_path, num_tiles, tiles_per_row, output_dir):
        """Generate a TSX file for the created tileset."""
        tsx_tree = ET.Element("tileset", version="1.10", tiledversion="1.10.2", name="GeneratedTileset",
                              tilewidth=str(self.tile_size), tileheight=str(self.tile_size),
                              tilecount=str(num_tiles), columns=str(tiles_per_row))
        ET.SubElement(tsx_tree, "image", source=os.path.relpath(tileset_path, output_dir),
                      width=str(tiles_per_row * self.tile_size), height=str((num_tiles // tiles_per_row + 1) * self.tile_size))

        tsx_path = os.path.join(output_dir, "JugdralTileset.tsx")
        tree = ET.ElementTree(tsx_tree)
        tree.write(tsx_path, encoding='utf-8', xml_declaration=True)
        print(f"Generated TSX file at: {tsx_path}")

    def process(self, tilemap_path, output_dir):
        self.extract_unique_tiles(tilemap_path)
        tileset_path, num_tiles, tiles_per_row = self.create_tileset_image(output_dir)
        self.generate_tsx(tileset_path, num_tiles, tiles_per_row, output_dir)

# Usage
tile_size = 16  # Define the size of each tile (16x16 pixels in this case)
output_directory = os.path.dirname(os.path.abspath(__file__))  # Use the script's directory
tilemap_path = os.path.join(output_directory, "Jugdral Continental Project.png")
creator = TilesetCreator(tile_size)
creator.process(tilemap_path, output_directory)