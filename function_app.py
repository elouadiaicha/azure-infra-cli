import azure.functions as func
import json

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="hello")
def hello(req: func.HttpRequest) -> func.HttpResponse:

    response = {
        "message": "Hello from AzureTech !",
        "service": "Azure Functions (Serverless)",
        "runtime": "Python 3.11",
        "trigger": "HTTP"
    }

    return func.HttpResponse(
        json.dumps(response),
        mimetype="application/json",
        status_code=200
    )