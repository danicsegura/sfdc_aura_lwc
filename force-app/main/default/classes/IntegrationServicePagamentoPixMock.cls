@isTest
public class IntegrationServicePagamentoPixMock implements HttpCalloutMock{
    public HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if(request.getEndpoint().contains('connect/token')){
            response.setBody('{' +
                                '"access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI3TFdPRDU1NFhhbThGUFMwbXprSmRtaGRqeDJORzNaYm14blBENTgtSHdvIn0.eyJqdGkiOiIxNzM3YjYzNC0zZDU2LTQ4ZjAtOTg0Ny1lM2E2MzlmNWU5YWIiLCJleHAiOjE2NDAxODY2NjksIm5iZiI6MCwiaWF0IjoxNjQwMTg2MDY5LCJpc3MiOiJodHRwczovL3Nzby1kLXNlZ3VyYW5jYS1kLmRldi5vY3AuY2FpeGFzZWd1cmFkb3JhLmludHJhbmV0L2F1dGgvcmVhbG1zL2ludGVybm8iLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiNTY5ZGYxOTUtNTI2MC00ZDc2LTgxMjQtMGRhZDU5ZmFjNTY2IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiMmZlMmVmNzEyNzhiZGI3NmNmZTM4MTA2YjdjMzkxYWEiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiJjM2JiN2ZmNS0yYmRkLTQ0NzQtYjVhNy03NjdlMWE5MTdmY2IiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6ImRlZmF1bHQtc2NvcGUiLCJjbGllbnRIb3N0IjoiMTAuMTE4LjAuMjAxIiwiY2xpZW50SWQiOiIyZmUyZWY3MTI3OGJkYjc2Y2ZlMzgxMDZiN2MzOTFhYSIsImNsaWVudEFkZHJlc3MiOiIxMC4xMTguMC4yMDEifQ.bC3fM9kDniLmXXfxkJMIDGoTi_adMnzhuFxUFd7Hftmyzzlog5-K0wadx2WBlZAAxXMAel3v46qfD-6lqWIkeuRZIce-57ZqHzqKH2eVu8Yzly8-z08QSBzqGaCet1VmIZjhR0TCxNtzAOyyHKU3Rhhy3qaYPZp3nsjU1kjLRKbuNgtjQXmsXGcCbJmb10fbbZ7oxWU-wi0c8afp8ME7GMlSS1A8fJrGsDT1E5a3AspyFFf9z46AfWxwhJRpIib_i-nrF6i2tpe9CmIXGRHZ0KmCrMXpLs1XwzgxrCt3gtjjwOCSy0xgj-TQhM-0bKuruddNtwPTb92l-y_K-bkfbg",' +
                                '"expires_in": 600,' +
                                '"refresh_expires_in": 1800,' +
                                '"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI1N2E0NmY5NC1mMzRlLTQxMTYtYjUxMi05NjRiNTY4MDgzYmQifQ.eyJqdGkiOiI4M2FhZjkzNS02ZmFmLTQ1NDItOTVjNi1iNjU3ZDI3NmNhZWQiLCJleHAiOjE2NDAxODc4NjksIm5iZiI6MCwiaWF0IjoxNjQwMTg2MDY5LCJpc3MiOiJodHRwczovL3Nzby1kLXNlZ3VyYW5jYS1kLmRldi5vY3AuY2FpeGFzZWd1cmFkb3JhLmludHJhbmV0L2F1dGgvcmVhbG1zL2ludGVybm8iLCJhdWQiOiJodHRwczovL3Nzby1kLXNlZ3VyYW5jYS1kLmRldi5vY3AuY2FpeGFzZWd1cmFkb3JhLmludHJhbmV0L2F1dGgvcmVhbG1zL2ludGVybm8iLCJzdWIiOiI1NjlkZjE5NS01MjYwLTRkNzYtODEyNC0wZGFkNTlmYWM1NjYiLCJ0eXAiOiJSZWZyZXNoIiwiYXpwIjoiMmZlMmVmNzEyNzhiZGI3NmNmZTM4MTA2YjdjMzkxYWEiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiJjM2JiN2ZmNS0yYmRkLTQ0NzQtYjVhNy03NjdlMWE5MTdmY2IiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoiZGVmYXVsdC1zY29wZSJ9.p2-UNe6Z7eJ9VvpULRMOU72rMaDYIpRS7uiYVb7JPcs",' +
                                '"token_type": "bearer",' +
                                '"not-before-policy": 0,' +
                                '"session_state": "c3bb7ff5-2bdd-4474-b5a7-767e1a917fcb",' +
                                '"scope": "default-scope"' +
                                '}');
        }else{
            response.setBody('{"identificacao": {"codigoNegocio": "123123123"},' +
                                '"parcela": {"numeroParcela": 1,"codigoModalidade": "1"},' +
                                '"produto": {"codigoProdutoNegocio": "123","cnpjEmpresa": "12121"},' +
                                '"valor": 0.03,' +
                                '"pix": {"txId": "EX23210000000000000000000000146","location": "pix-h.santander.com.br/qr/v2/ba38bfa8-dc7f-4ced-b7cc-bef4c8282c45",' +
                                    '"expiracao": "891798","chave": "20201210000155"},' +
                                '"informacoesAdicionais": [{"nome": "AAA","valor": "Valor9"}],' +
                                '"dataCobranca": "2022-01-01T20:00:00Z",' +
                                '"pagador": {"nome": "DIEGO PEREIRA AIRES","cpfCnpj": "01709467118"},' +
                                '"descricaoCobranca": "Cobrança dos serviços prestados.",' +
                                '"dataCriacao": "2021-12-22T12:16:42Z"' +
                                '}');
        }

        response.setStatusCode(200);
        return response;
    }
}