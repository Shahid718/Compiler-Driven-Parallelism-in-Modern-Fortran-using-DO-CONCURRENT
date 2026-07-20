#!/usr/bin/env python3
"""
read_binary_ch.py
Python script to read binary output from the Cahn-Hilliard simulation
and display results with visualization.
"""

import numpy as np
import struct
import sys
import os

def read_binary_ch(filename):
    """
    Read binary Cahn-Hilliard output file
    
    Returns:
        con: concentration field (2D numpy array)
        stats: dictionary with metadata
    """
    with open(filename, 'rb') as f:
        # Read header (32-bit integers and floats)
        magic = struct.unpack('I', f.read(4))[0]
        version = struct.unpack('I', f.read(4))[0]
        nx = struct.unpack('I', f.read(4))[0]
        ny = struct.unpack('I', f.read(4))[0]
        precision = struct.unpack('I', f.read(4))[0]
        min_val = struct.unpack('f', f.read(4))[0]
        max_val = struct.unpack('f', f.read(4))[0]
        mean_val = struct.unpack('f', f.read(4))[0]
        
        # Read data
        data = np.fromfile(f, dtype=np.float32, count=nx*ny)
        con = data.reshape(nx, ny)
        
        stats = {
            'nx': nx,
            'ny': ny,
            'min': min_val,
            'max': max_val,
            'mean': mean_val,
            'version': version,
            'magic': magic,
            'precision': 'single' if precision == 1 else 'double'
        }
        
        return con, stats

def save_real_data(con, filename='ch_real.dat'):
    """
    Write the concentration field to a plain-text file of real numbers,
    one row per line, space-separated.
    """
    np.savetxt(filename, con, fmt='%.6f')
    print(f'  ✓ Real-number data saved as: {filename}')

def plot_concentration(con, stats):
    """
    Plot the concentration field with matplotlib
    """
    try:
        import matplotlib.pyplot as plt
        
        fig, ax = plt.subplots(1, 1, figsize=(8, 6))
        
        # 2D heatmap
        im = ax.imshow(con, cmap='jet', aspect='auto', interpolation='bilinear')
        ax.set_title(f'Concentration Field\n({stats["nx"]} x {stats["ny"]})')
        ax.set_xlabel('X')
        ax.set_ylabel('Y')
        plt.colorbar(im, ax=ax, label='Concentration (c)')
        
        plt.tight_layout()
        plt.savefig('concentration_plot.png', dpi=150)
        print('  ✓ Figure saved as: concentration_plot.png')
        plt.show()
        
    except ImportError:
        print('  ⚠ matplotlib not installed. Install with: pip install matplotlib')

def main():
    """Main program to read and display binary output"""
    
    # Default input file
    input_file = "../build/bin/ch.dat"
    
    # Parse command line
    if len(sys.argv) >= 2:
        input_file = sys.argv[1]
    
    print('╔══════════════════════════════════════════════════════════════════════╗')
    print('║                    BINARY OUTPUT READER                              ║')
    print('║                         Cahn-Hilliard Output                         ║')
    print('╚══════════════════════════════════════════════════════════════════════╝')
    print()
    print(f'  Input file  : {input_file}')
    print()
    
    # Check if input file exists
    if not os.path.exists(input_file):
        print(f'  ✗ ERROR: File not found: {input_file}')
        sys.exit(1)
    
    # Read binary file
    print('  Reading binary file...')
    try:
        con, stats = read_binary_ch(input_file)
    except Exception as e:
        print(f'  ✗ ERROR: Could not read binary file: {e}')
        sys.exit(1)
    
    # Display statistics
    print(f'  ✓ Magic number: 0x{stats["magic"]:08X}')
    print(f'  ✓ Version: {stats["version"]}')
    print(f'  ✓ Grid: {stats["nx"]} x {stats["ny"]}')
    print(f'  ✓ Precision: {stats["precision"]}')
    print(f'  ✓ Statistics:')
    print(f'      - Min: {stats["min"]:.6f}')
    print(f'      - Max: {stats["max"]:.6f}')
    print(f'      - Mean: {stats["mean"]:.6f}')
    print()
    
    # Display sample data
    print('  Sample Data (first 5x5):')
    print('  ════════════════════════════════════════════════════════════════════')
    for i in range(min(5, stats["nx"])):
        row_str = ' '.join([f'{con[i,j]:.6f}' for j in range(min(5, stats["ny"]))])
        print(f'    {row_str}')
    print()
    
    # Save full field as real-number text data
    save_real_data(con)
    print()

    # Plot the data
    print('  Generating plot first 100 x 100...')
    plot_concentration(con[:100, :100], stats)
    
    print()
    print('╔══════════════════════════════════════════════════════════════════════╗')
    print('║                    READING COMPLETE                                  ║')
    print(f'║    Grid points    : {stats["nx"] * stats["ny"]}                                           ║ ')                    
    print('║                                                                      ║')
    print('║    ✓ Data read successfully!                                         ║')
    print('╚══════════════════════════════════════════════════════════════════════╝')

if __name__ == '__main__':
    main()    