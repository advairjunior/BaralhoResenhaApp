namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Jurados: o app elege uma pessoa e o resto dá nota de 1 a 5 estrelas, em
/// segredo. As notas aparecem sem dizer quem deu qual.
/// </summary>
public sealed partial class Sala
{
    /// <summary>Média a partir da qual a pessoa é aprovada e distribui goles.</summary>
    internal const double NotaParaAprovar = 4.0;

    /// <summary>Média até a qual a pessoa é reprovada e leva o ponto.</summary>
    internal const double NotaParaReprovar = 2.0;

    private Revelacao RevelarJurados(Rodada rodada, List<KeyValuePair<Guid, string>> respostas)
    {
        var avaliado = _jogadores.FirstOrDefault(j => j.Id == rodada.Alvo);
        var notas = respostas.Where(r => r.Key != rodada.Alvo).Select(r => int.Parse(r.Value)).Order().ToList();
        var media = notas.Count > 0 ? notas.Average() : 0;
        var aprovado = avaliado is not null && notas.Count > 0 && media >= NotaParaAprovar;
        var reprovado = avaliado is not null && notas.Count > 0 && media <= NotaParaReprovar;
        if (aprovado)
        {
            DarCarta(avaliado!);
            avaliado!.Estatisticas.Elogios += notas.Count;
        }
        return new Revelacao([], [], [], reprovado ? [avaliado!.Id] : [], null, Elogio: aprovado)
        {
            Escolhidos = aprovado ? [avaliado!.Id] : [],
            Media = Math.Round(media, 1, MidpointRounding.AwayFromZero),
            Notas = notas,
        };
    }
}
