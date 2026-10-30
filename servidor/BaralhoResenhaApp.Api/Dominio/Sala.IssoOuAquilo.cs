namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// ⚖️ Isso ou aquilo: a carta dá duas opções e cada um escolhe em segredo
/// ("0" ou "1"). Quem ficou na minoria leva ponto; empate ou todo mundo do
/// mesmo lado, ninguém leva.
/// </summary>
public sealed partial class Sala
{
    private static void ValidarEscolha(string resposta)
    {
        if (resposta is not ("0" or "1")) throw new AcaoNaoPermitidaException("Escolha uma das duas.");
    }

    private static Revelacao RevelarEscolhas(List<KeyValuePair<Guid, string>> respostas)
    {
        IReadOnlyList<Guid> Lado(string opcao) => respostas.Where(r => r.Value == opcao).Select(r => r.Key).ToList();
        var (isso, aquilo) = (Lado("0"), Lado("1"));
        IReadOnlyList<Guid> minoria = isso.Count == aquilo.Count || isso.Count == 0 || aquilo.Count == 0
            ? []
            : isso.Count < aquilo.Count ? isso : aquilo;
        return new Revelacao([], [], [], minoria, null) { Lados = [isso, aquilo] };
    }
}
