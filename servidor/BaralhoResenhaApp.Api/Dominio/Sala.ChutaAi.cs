using System.Globalization;

namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Chuta aí: a carta faz uma pergunta com resposta em número e cada um chuta
/// em segredo. Quem chutou mais longe leva ponto; quem chegou mais perto
/// distribui goles (como no elogio); na mosca ganha uma carta na manga.
/// </summary>
public sealed partial class Sala
{
    /// <summary>"42,195" ou "42.195": o teclado do celular decide; guarda sempre com ponto.</summary>
    private static string ValidarChute(string resposta)
    {
        var texto = (resposta ?? string.Empty).Trim().Replace(',', '.');
        if (!decimal.TryParse(texto, NumberStyles.AllowLeadingSign | NumberStyles.AllowDecimalPoint,
                CultureInfo.InvariantCulture, out var chute))
            throw new AcaoNaoPermitidaException("Chute um número.");
        return chute.ToString(CultureInfo.InvariantCulture);
    }

    private Revelacao RevelarChutes(Rodada rodada, List<KeyValuePair<Guid, string>> respostas)
    {
        var certa = rodada.Carta.Resposta ?? 0;
        var chutes = respostas
            .Select(r => new ChuteRevelado(r.Key, decimal.Parse(r.Value, CultureInfo.InvariantCulture)))
            .OrderBy(c => Math.Abs(c.Valor - certa))
            .ToList();
        var distancias = chutes.Select(c => Math.Abs(c.Valor - certa)).Distinct().ToList();
        // Todo mundo à mesma distância: ninguém ficou mais perto nem mais longe.
        List<Guid> NaDistancia(decimal distancia) => distancias.Count > 1
            ? chutes.Where(c => Math.Abs(c.Valor - certa) == distancia).Select(c => c.JogadorId).ToList()
            : [];
        var maisPerto = NaDistancia(distancias.FirstOrDefault());
        var maisLonge = NaDistancia(distancias.LastOrDefault());
        foreach (var jogador in _jogadores.Where(j => chutes.Any(c => c.JogadorId == j.Id && c.Valor == certa)))
            DarCarta(jogador);
        return new Revelacao([], [], [], maisLonge, null, Elogio: maisPerto.Count > 0)
        {
            Escolhidos = maisPerto,
            RespostaCerta = certa,
            Chutes = chutes,
        };
    }
}
