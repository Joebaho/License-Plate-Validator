"""
California License Plate Validator
Supports historical and modern plate patterns.
"""
import random
import re


class CaliforniaPlateValidator:
    def __init__(self):
        # Comprehensive regex patterns keyed by human-readable format labels.
        self.patterns = {
            # Historical Formats (1914-2000)
            "1914-1920: Simple numeric (1-5 digits)": r"^\d{1,5}$",
            "1920-1928: 6-digit format": r"^\d{6}$",
            "1929-1934: ABC-123 pattern": r"^[A-Z]{3}-\d{3}$",
            "1956-1969: ABC 123": r"^[A-Z]{3}\s\d{3}$",
            "1970-1980: 123 ABC": r"^\d{3}\s[A-Z]{3}$",
            "1981-2000: 1ABC123": r"^[1-9][A-Z]{3}\d{3}$",
            # Modern Formats (2001-Present)
            "Standard: 1ABC123": r"^[1-9][A-Z]{3}\d{3}$",
            "Commercial: AB123CD": r"^[A-Z]{2}\d{3}[A-Z]{2}$",
            "Motorcycle: ABC1234": r"^[A-Z]{3}\d{4}$",
            "Personalized: SURFER (1-7 letters)": r"^[A-Z]{1,7}$",
            "Legislative: S123456": r"^S\d{6}$",
            "Exempt: E123456": r"^E\d{6}$",
            "Livery: L123456": r"^L\d{6}$",
        }

        self.format_groups = {
            "historical_formats_1914_2000": [
                "1914-1920: Simple numeric (1-5 digits)",
                "1920-1928: 6-digit format",
                "1929-1934: ABC-123 pattern",
                "1956-1969: ABC 123",
                "1970-1980: 123 ABC",
                "1981-2000: 1ABC123",
            ],
            "modern_formats_2001_present": [
                "Standard: 1ABC123",
                "Commercial: AB123CD",
                "Motorcycle: ABC1234",
                "Personalized: SURFER (1-7 letters)",
                "Legislative: S123456",
                "Exempt: E123456",
                "Livery: L123456",
            ],
        }

        self.sample_plates = [
            "12345",
            "123456",
            "ABC-123",
            "ABC 123",
            "123 ABC",
            "1ABC123",
            "AB123CD",
            "ABC1234",
            "SURFER",
            "S123456",
            "E123456",
            "L123456",
        ]

    def sanitize_plate(self, plate_number):
        """Normalize user input before validation."""
        if plate_number is None:
            return ""
        return str(plate_number).upper().strip()

    def suggest_corrections(self, plate):
        """Suggest likely corrections for common OCR/typing mistakes."""
        suggestions = []
        replacement_candidates = [
            plate.replace("O", "0"),
            plate.replace("0", "O"),
            plate.replace("I", "1"),
            plate.replace("1", "I"),
            plate.replace("-", ""),
            plate.replace(" ", ""),
        ]

        seen = set()
        for candidate in replacement_candidates:
            if candidate in seen:
                continue
            seen.add(candidate)
            if candidate != plate and self.validate_plate(candidate)[0]:
                suggestions.append(candidate)

        return suggestions[:3]

    def validate_plate(self, plate_number):
        """
        Validate a California license plate.
        Returns: (is_valid, format_type, message)
        """
        plate = self.sanitize_plate(plate_number)
        if not plate:
            return False, "Invalid", "Plate number cannot be empty"

        # Input sanitization used by some pattern checks.
        plate_compact = plate.replace(" ", "").replace("-", "")

        if len(plate_compact) < 1 or len(plate_compact) > 7:
            return False, "Invalid", "Plate must be 1-7 characters (excluding spaces/hyphens)"

        for label, pattern in self.patterns.items():
            target = plate
            # Patterns without explicit separators should validate against compact representation.
            if "\\s" not in pattern and "-" not in pattern:
                target = plate_compact
            if re.match(pattern, target):
                return True, label, f"Valid format: {label}"

        return False, "Invalid", "Does not match known California plate patterns"

    def generate_random_plate(self):
        return random.choice(self.sample_plates)

    def get_format_catalog(self):
        """Return browser-ready format catalog."""
        return {
            "historical_formats_1914_2000": self.format_groups["historical_formats_1914_2000"],
            "modern_formats_2001_present": self.format_groups["modern_formats_2001_present"],
            "patterns": self.patterns,
        }

    def get_plate_info(self, plate_number):
        plate = self.sanitize_plate(plate_number)
        is_valid, format_type, message = self.validate_plate(plate)
        suggestions = self.suggest_corrections(plate) if not is_valid else []

        return {
            "plate": plate,
            "is_valid": is_valid,
            "format_type": format_type,
            "message": message,
            "character_count": len(plate.replace(" ", "").replace("-", "")),
            "has_special_chars": any(c in plate for c in " -"),
            "suggested_correction": suggestions[0] if suggestions else None,
            "suggestions": suggestions,
        }


validator = CaliforniaPlateValidator()
