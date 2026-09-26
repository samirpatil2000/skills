#!/usr/bin/env python3
"""
Figure extraction utilities for AI Paper Reader skill.
Supports extracting embedded images, clustered vector graphics, and manual cropping from academic PDFs.
"""

import argparse
import os
import sys

try:
    import fitz  # PyMuPDF
except ImportError:
    print("Error: PyMuPDF is not installed. Run `pip install pymupdf`.", file=sys.stderr)
    sys.exit(1)


def extract_embedded_images(pdf_path, output_dir):
    """Extract bitmap images embedded in the PDF"""
    os.makedirs(output_dir, exist_ok=True)
    doc = fitz.open(pdf_path)
    extracted = []

    for page_num in range(len(doc)):
        page = doc[page_num]
        images = page.get_images(full=True)

        for img_idx, img in enumerate(images):
            xref = img[0]
            base = doc.extract_image(xref)
            image_bytes = base["image"]
            image_ext = base["ext"]

            # Filter out images that are too small (likely icons/decoration)
            if base["width"] > 100 and base["height"] > 100:
                output_path = os.path.join(output_dir, f"page{page_num+1}_img{img_idx+1}.{image_ext}")
                with open(output_path, "wb") as f:
                    f.write(image_bytes)
                extracted.append(output_path)

    doc.close()
    return extracted


def extract_vector_figures(pdf_path, output_dir, dpi=200, min_size=100, x_tolerance=3, y_tolerance=3):
    """
    Use cluster_drawings() to identify vector-graphic regions and screenshot them.
    """
    os.makedirs(output_dir, exist_ok=True)
    doc = fitz.open(pdf_path)
    figures = []

    for page_num in range(len(doc)):
        page = doc[page_num]

        try:
            drawing_rects = page.cluster_drawings(
                x_tolerance=x_tolerance,
                y_tolerance=y_tolerance
            )
        except Exception:
            continue

        for idx, rect in enumerate(drawing_rects):
            if rect.width < min_size or rect.height < min_size:
                continue

            rect = (rect + (-10, -10, 10, 10)) & page.rect
            zoom = dpi / 72
            mat = fitz.Matrix(zoom, zoom)
            pix = page.get_pixmap(matrix=mat, clip=rect)

            output_path = os.path.join(output_dir, f"page{page_num+1}_fig{idx+1}.png")
            pix.save(output_path)
            figures.append({
                "page": page_num + 1,
                "path": output_path,
                "rect": rect
            })

    doc.close()
    return figures


def crop_figure(pdf_path, page_num, rect, output_path, dpi=200):
    """
    Crop a specific region from a given page of a PDF.
    rect: (x0, y0, x1, y1) in points (pt)
    """
    doc = fitz.open(pdf_path)
    page = doc[page_num - 1]

    clip = fitz.Rect(rect)
    zoom = dpi / 72
    mat = fitz.Matrix(zoom, zoom)

    pix = page.get_pixmap(matrix=mat, clip=clip)
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    pix.save(output_path)
    doc.close()


def smart_extract_figures(pdf_path, output_dir, dpi=200):
    """
    Intelligently extract all figures from a paper:
    1. Identify vector graphics via cluster_drawings
    2. Extract embedded bitmaps
    """
    os.makedirs(output_dir, exist_ok=True)
    doc = fitz.open(pdf_path)
    results = {"vector": [], "embedded": []}

    for page_num in range(len(doc)):
        page = doc[page_num]

        # 1. Extract vector graphics
        try:
            rects = page.cluster_drawings(x_tolerance=3, y_tolerance=3)
            for idx, rect in enumerate(rects):
                if rect.width > 100 and rect.height > 100:
                    rect = (rect + (-10, -10, 10, 10)) & page.rect
                    zoom = dpi / 72
                    pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), clip=rect)
                    path = os.path.join(output_dir, f"p{page_num+1}_vec{idx+1}.png")
                    pix.save(path)
                    results["vector"].append(path)
        except Exception:
            pass

        # 2. Extract embedded images
        for img_idx, img in enumerate(page.get_images(full=True)):
            xref = img[0]
            base = doc.extract_image(xref)
            if base["width"] > 100 and base["height"] > 100:
                path = os.path.join(output_dir, f"p{page_num+1}_img{img_idx+1}.{base['ext']}")
                with open(path, "wb") as f:
                    f.write(base["image"])
                results["embedded"].append(path)

    doc.close()
    print(f"Extraction complete: {len(results['vector'])} vector figures, {len(results['embedded'])} bitmaps saved to {output_dir}")
    return results


def main():
    parser = argparse.ArgumentParser(description="Extract figures from an academic paper PDF")
    parser.add_argument("pdf_path", help="Path to PDF paper")
    parser.add_argument("-o", "--output-dir", default="./images", help="Output directory for extracted images")
    parser.add_argument("--dpi", type=int, default=200, help="DPI for rasterized graphics (default: 200)")
    parser.add_argument("--mode", choices=["smart", "vector", "embedded"], default="smart", help="Extraction mode")

    args = parser.parse_args()

    if not os.path.isfile(args.pdf_path):
        print(f"Error: File not found: {args.pdf_path}", file=sys.stderr)
        sys.exit(1)

    if args.mode == "smart":
        smart_extract_figures(args.pdf_path, args.output_dir, dpi=args.dpi)
    elif args.mode == "vector":
        vecs = extract_vector_figures(args.pdf_path, args.output_dir, dpi=args.dpi)
        print(f"Extracted {len(vecs)} vector figures to {args.output_dir}")
    elif args.mode == "embedded":
        imgs = extract_embedded_images(args.pdf_path, args.output_dir)
        print(f"Extracted {len(imgs)} embedded images to {args.output_dir}")


if __name__ == "__main__":
    main()
