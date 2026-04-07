from flask import Flask, render_template, request, jsonify, Response
from plate_validator import validator
import json

app = Flask(__name__)

@app.route('/')
def index():
    """Render main page"""
    return render_template('index.html')

@app.route('/api/validate', methods=['POST'])
def validate():
    """Validate a license plate"""
    data = request.get_json()
    
    if not data or 'plate' not in data:
        return jsonify({
            "error": "Plate number is required",
            "plate": None,
            "is_valid": False
        }), 400
    
    plate_number = data['plate']
    info = validator.get_plate_info(plate_number)
    
    return jsonify(info)

@app.route('/api/random')
def get_random():
    """Get a random valid plate number"""
    plate = validator.generate_random_plate()
    info = validator.get_plate_info(plate)
    return jsonify(info)

@app.route('/api/bulk-validate', methods=['POST'])
def bulk_validate():
    """Validate multiple plates at once"""
    data = request.get_json()
    
    if not data or 'plates' not in data:
        return jsonify({"error": "Plates array is required"}), 400
    
    results = []
    for plate in data['plates']:
        if plate:
            info = validator.get_plate_info(plate)
            results.append(info)
    
    return jsonify({
        "count": len(results),
        "valid_count": sum(1 for r in results if r['is_valid']),
        "results": results
    })

@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "California Plate Validator",
        "version": "1.0.0"
    })

@app.route('/api/formats')
def get_formats():
    """Get all supported plate formats"""
    return jsonify({
        "formats": validator.get_format_catalog(),
        "total_formats": len(validator.patterns)
    })

# Server-Sent Events for real-time validation
@app.route('/api/stream')
def stream():
    """Stream random plate validations"""
    def generate():
        while True:
            plate = validator.generate_random_plate()
            info = validator.get_plate_info(plate)
            yield f"data: {json.dumps(info)}\n\n"
    
    return Response(generate(), mimetype='text/event-stream')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
